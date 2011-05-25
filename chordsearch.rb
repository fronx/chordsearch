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

get '/mandolin/import' do
  # source: https://github.com/gudmundurh/progressions/blob/master/chords/mandolindb.js
  [
    ["C", "major", "0230"],
    ["C", "major", "0233"],
    ["C#/Db", "major", "1341"],
    ["D", "major", "2002"],
    ["D#/Eb", "major", "0113"],
    ["E", "major", "4224"],
    ["F", "major", "5301"],
    ["F#/Gb", "major", "6412"],
    ["G", "major", "0023"],
    ["G#/Ab", "major", "1134"],
    ["A", "major", "6200"],
    ["A#/Bb", "major", "3011"],
    ["B", "major", "4467"],
    ["C", "minor", "0133"],
    ["A#/Bb", "minor", "3346"],
    ["C", "7", "0213"],
    ["F", "minor", "1334"],
    ["D#/Eb", "minor", "3466"],
    ["F", "7", "2131"],
    ["G", "minor", "0013"],
    ["G#/Ab", "minor", "1124"],
    ["G", "7", "0021"],
    ["D", "minor", "2001"],
    ["C#/Db", "minor", "1244"],
    ["D", "7", "2032"],
    ["F#/Gb", "major", "3446"],
    ["A", "major", "2245"],
    ["A", "minor", "5200"],
    ["A", "minor", "2235"],
    ["F#/Gb", "minor", "2445"],
    ["A", "7", "2243"],
    ["E", "major", "1224"],
    ["E", "minor", "0223"],
    ["B", "minor", "4022"],
    ["E", "7", "1020"],
    ["A#/Bb", "7", "3354"],
    ["D#/Eb", "7", "3143"],
    ["G#/Ab", "7", "1132"],
    ["C#/Db", "7", "1324"],
    ["F#/Gb", "7", "3440"],
    ["B", "7", "4405"],
    ["C", "m7", "3133"],
    ["F", "m7", "131"],
    ["G", "m7", "0011"],
    ["D", "m7", "2031"],
    ["A", "m7", "2233"],
    ["E", "m7", "0010"],
    ["A#/Bb", "m7", "3344"],
    ["D#/Eb", "m7", "3142"],
    ["G#/Ab", "m7", "1122"],
    ["C#/Db", "m7", "4244"],
    ["F#/Gb", "m7", "2440"],
    ["B", "m7", "2022"],
  ].each do |data|
    ChordDB.insert('mandolin', {
      'chord' => data[0],
      'modifier' => data[1],
      'g' => data[2].chars.to_a[0],
      'd' => data[2].chars.to_a[1],
      'a' => data[2].chars.to_a[2],
      'e' => data[2].chars.to_a[3],
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
