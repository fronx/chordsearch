require 'sinatra'
require 'mongo'
require 'haml'
require 'json'
require 'cgi'

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

class Chord
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
    @data = Hash[strings.reverse.map { |s| [s, raw[s] || '0'] }]
  end

  def url_html
    "http://chordsearch.heroku.com/#{self.class.instrument}/#{key}"
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

  def strings
    self.class.strings
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
      "instrument" => self.class.instrument,
      "chord"      => chord,
      "modifier"   => modifier,
      "url_html"   => url_html,
      "url_json"   => url_json,
      "tones"      => data
    }.to_json
  end
end

class SoundCloud
  def self.set_url(user, name)
    "http://soundcloud.com/#{user}/sets/#{name}/?v=1"
  end
end

class GuitarChord < Chord
  def self.dummy
    new('chord' => 'A', 'modifier' => 'major', 'b' => '2', 'g' => '2', 'D' => '2')
  end

  def self.instrument
    'guitar'
  end

  def self.strings
    ['E', 'A', 'D', 'g', 'b', 'e']
  end

  def self.string_sets
    [
      'e-1', 'a', 'd',
      'g'  , 'b', 'e'
    ].map do |string|
      SoundCloud.set_url('fronx', "guitar-string-#{string}")
    end
  end
end

class UkuleleChord < Chord
  def self.dummy
    new('chord' => 'G', 'modifier' => 'major', 'c' => '2', 'e' => '3', 'a' => '2')
  end

  def self.instrument
    'ukulele'
  end

  def self.strings
    ['g', 'c', 'e', 'a']
  end
end

class MandolinChord < Chord
  def self.dummy
    new('chord' => 'C', 'modifier' => 'major', 'd' => '2', 'a' => '3')
  end

  def self.instrument
    'mandolin'
  end

  def self.strings
    ['g', 'd', 'a', 'e']
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
        'guitar'   => GuitarChord,
        'ukulele'  => UkuleleChord,
        'mandolin' => MandolinChord,
      }[instrument.downcase]
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

get %r{^/(\w+)$} do |instrument|
  redirect "/#{instrument}/"
end

get %r{^/(\w+)/$} do |instrument|
  redirect '/' unless @chord_class = ChordDB[instrument]
  @query = {}
  @search_chord = @chord_class.new
  @chords = []
  haml :chords
end

get %r{^/(\w+)/(.*\.json)$} do |instrument, q|
  query = ChordDB.query_from_param(q)
  ChordDB.find_chords(query, instrument).to_json
end

get %r{^/(\w+)/(.*)$} do |instrument, q|
  @chord_class = ChordDB[instrument]
  @query = ChordDB.query_from_param(q)
  @search_chord = @chord_class.search_chord(@query)
  @chords = ChordDB.find_chords(@query, instrument)
  haml :chords
end
