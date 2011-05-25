require 'sinatra'
require 'mongo'
require 'haml'
require 'json'

set :app_file, __FILE__
enable :static

Hash.class_eval do
  def slice(*keys)
    allowed = Set.new(respond_to?(:convert_key) ? keys.map { |key| convert_key(key) } : keys)
    hash = {}
    allowed.each { |k| hash[k] = self[k] if has_key?(k) }
    hash
  end
end

class GuitarChord
  def self.dummy
    new('chord' => 'A', 'modifier' => 'major', 'b' => '2', 'g' => '2', 'D' => '2')
  end

  def self.instrument
    'guitar'
  end

  def self.search_chord(query)
    new(query)
  end

  def self.modifiers
    [
      'major', 'minor', '7', 'm7', 'maj7', 'mmaj7', '6', 'm6', 'sus', 'dim', 'aug',
      '7sus4', '5', '-5', '7-5', '7maj5', 'm9', 'maj9', 'add9', '11', '13', '6add9'
    ]
  end

  attr_reader :chord, :modifier, :data

  def initialize(raw = {})
    @chord = raw['chord']
    @modifier = raw['modifier']
    @raw = raw.slice(*strings)
    @data = Hash[strings.map { |s| [s, raw[s] || '0'] }]
  end

  def strings
    ['E', 'A', 'D', 'g', 'b', 'e'].reverse
  end

  def url_html
    "http://chordsearch.heroku.com/guitar/#{key}"
  end

  def url_json
    "#{url_html}.json"
  end

  def key
    strings.map { |s| [s, data[s]] }.flatten.join <<
      '--' << name.gsub(/\s+/, '_')
  end

  def obscurity_score
    self.class.modifiers.index(modifier) || self.class.modifiers.length
  end

  def distance(other)
    data.inject(0) do |memo, string_fret|
      string, fret = string_fret
      this_fret = fret == 'x' ? -5 : fret.to_i
      other_fret = other.data[string] == 'x' ? -5 : other.data[string].to_i
      memo + (this_fret - other_fret).abs
    end
  end

  def search_key
    @raw.to_a.flatten.join
  end

  def self.search_path(q)
    path = new(q).search_key
    path == '' ? "/#{instrument}/#{path}" : path
  end

  def name
    [chord, modifier].join(' ')
  end

  def to_json(*args)
    {
      "instrument" => "guitar",
      "chord"      => chord,
      "modifier"   => modifier,
      "url_html"   => url_html,
      "url_json"   => url_json,
      "tones"      => data
    }.to_json
  end
end

module ChordDB
  def self.connect
    uri = URI.parse(ENV['MONGOHQ_URL'])
    conn = Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
    @db = conn.db(uri.path.gsub(/^\//, ''))
  end

  class << self
    def chord_class(instrument)
      {
        'guitar' => GuitarChord,
      }[instrument]
    end
    alias :[] :chord_class
  end

  def self.db
    @db ||= connect
  end

  def self.query_from_param(q)
    query = {} if q == 'all'
    query ||= Hash[
      q.to_s.split('--').first.scan(/([a-zA-Z])(\d+)/) # [['e', '5'], ['b', '6']]
    ] # {'e' => '5', 'b' => '6'}
  end

  def self.find_chords(query, instrument)
    chords = ENV['NOINTERNET'] ? [GuitarChord.dummy] :
      db[instrument].find(query).map do |result|
        chord_class(instrument).new(result)
      end
    search_chord = chord_class(instrument).search_chord(query)
    chords.sort_by do |chord|
      [
        chord.distance(search_chord),
        chord.obscurity_score,
      ]
    end
  end

  def self.insert(instrument, data)
    db[instrument].insert(data)
  end
end

get '/' do
  haml :index
end

get '/ukulele/import' do
  # source: https://github.com/gudmundurh/progressions/blob/master/chords/ukuleledb.js
  [
    ["C", "major", "0003"],
    ["C", "7", "0001"],
    ["C", "minor", "0333"],
    ["C", "m7", "3333"],
    ["C", "dim", "2323"],
    ["C", "aug", "1003"],
    ["C", "6", "0000"],
    ["C", "maj7", "0002"],
    ["C", "9", "0201"],
    ["C#/Db", "major", "1114"],
    ["C#/Db", "7", "1112"],
    ["C#/Db", "minor", "1103"],
    ["C#/Db", "minor", "6444"],
    ["C#/Db", "m7", "4444"],
    ["C#/Db", "dim", "0101"],
    ["C#/Db", "aug", "2110"],
    ["C#/Db", "6", "1111"],
    ["C#/Db", "maj7", "1113"],
    ["C#/Db", "9", "1312"],
    ["D", "major", "2225"],
    ["D", "7", "2223"],
    ["D", "minor", "2210"],
    ["D", "m7", "2213"],
    ["D", "m7", "5555"],
    ["C#/Db", "dim", "1212"],
    ["D", "aug", "3221"],
    ["D", "6", "2222"],
    ["D", "maj7", "2224"],
    ["D", "9", "2423"],
    ["D#/Eb", "major", "3331"],
    ["D#/Eb", "7", "3334"],
    ["D#/Eb", "minor", "3321"],
    ["D#/Eb", "m7", "3324"],
    ["D#/Eb", "dim", "2323"],
    ["D#/Eb", "aug", "2114"],
    ["D#/Eb", "6", "3333"],
    ["D#/Eb", "maj7", "3330"],
    ["D#/Eb", "9", "0111"],
    ["E", "major", "4441"],
    ["E", "7", "1202"],
    ["E", "minor", "0432"],
    ["E", "m7", "0202"],
    ["E", "dim", "0101"],
    ["E", "aug", "1003"],
    ["E", "6", "1020"],
    ["E", "6", "4444"],
    ["E", "maj7", "1302"],
    ["E", "maj7", "4446"],
    ["E", "9", "1222"],
    ["F", "major", "2010"],
    ["F", "7", "2310"],
    ["F", "minor", "1013"],
    ["F", "m7", "1313"],
    ["F", "dim", "1212"],
    ["F", "aug", "211"],
    ["F", "6", "2213"],
    ["F", "maj7", "2413"],
    ["F", "maj7", "5555"],
    ["F", "9", "2333"],
    ["F#/Gb", "major", "3121"],
    ["F#/Gb", "7", "3424"],
    ["F#/Gb", "minor", "2120"],
    ["F#/Gb", "m7", "2424"],
    ["F#/Gb", "dim", "2323"],
    ["F#/Gb", "aug", "4322"],
    ["F#/Gb", "6", "3324"],
    ["F#/Gb", "maj7", "0111"],
    ["F#/Gb", "9", "1101"],
    ["G", "major", "0232"],
    ["G", "7", "0212"],
    ["G", "minor", "0231"],
    ["G", "m7", "0211"],
    ["G", "dim", "0101"],
    ["G", "dim", "3434"],
    ["G", "aug", "4332"],
    ["G", "6", "0202"],
    ["G", "maj7", "0222"],
    ["G", "9", "2212"],
    ["G#/Ab", "major", "5343"],
    ["G#/Ab", "7", "1323"],
    ["G#/Ab", "minor", "1342"],
    ["G#/Ab", "m7", "0322"],
    ["G#/Ab", "dim", "1212"],
    ["G#/Ab", "aug", "1000"],
    ["G#/Ab", "aug", "5443"],
    ["G#/Ab", "6", "1313"],
    ["G#/Ab", "maj7", "1333"],
    ["G#/Ab", "9", "3323"],
    ["A", "major", "2100"],
    ["A", "7", "0100"],
    ["A", "minor", "2000"],
    ["A", "m7", "0433"],
    ["A", "dim", "2323"],
    ["A", "aug", "2111"],
    ["A", "aug", "6554"],
    ["A", "6", "2424"],
    ["A", "maj7", "1100"],
    ["A", "maj7", "2444"],
    ["A", "9", "0102"],
    ["A#/Bb", "major", "3211"],
    ["A#/Bb", "7", "1211"],
    ["A#/Bb", "minor", "3111"],
    ["A#/Bb", "m7", "1111"],
    ["A#/Bb", "dim", "0101"],
    ["A#/Bb", "aug", "3221"],
    ["A#/Bb", "6", "0211"],
    ["A#/Bb", "maj7", "3210"],
    ["A#/Bb", "9", "1213"],
    ["B", "major", "4322"],
    ["B", "7", "2322"],
    ["B", "minor", "4222"],
    ["B", "m7", "2222"],
    ["B", "dim", "1212"],
    ["B", "aug", "4332"],
    ["B", "6", "1322"],
    ["B", "maj7", "3322"],
    ["B", "9", "2324"],
  ].each do |data|
    ChordDB.insert('ukulele', {
      'chord' => data[0],
      'modifier' => data[1],
      'g' => data[2].chars.to_a[0],
      'c' => data[2].chars.to_a[1],
      'e' => data[2].chars.to_a[2],
      'a' => data[2].chars.to_a[3],
    })
  end
  "done"
end

get %r{^/(\w+)$} do |instrument|
  redirect "/#{instrument}/"
end

get %r{^/(\w+)/$} do |instrument|
  redirect '/' unless ChordDB[instrument]
  @query = {}
  @search_chord = ChordDB[instrument].new
  @chords = []
  haml :chords
end

get %r{^/(\w+)/(.*\.json)$} do |instrument, q|
  query = ChordDB.query_from_param(q)
  ChordDB.find_chords(query, instrument).to_json
end

get %r{^/(\w+)/(.*)$} do |instrument, q|
  @query = ChordDB.query_from_param(q)
  @search_chord = ChordDB[instrument].search_chord(@query)
  @chords = ChordDB.find_chords(@query, instrument)
  haml :chords
end
