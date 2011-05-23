require 'sinatra'
require 'mongo'
require 'haml'
require 'json'

class GuitarChord
  def strings
    ['E', 'A', 'D', 'g', 'b', 'e'].reverse
  end

  attr_reader :chord, :modifier, :data

  def initialize(raw)
    @chord = raw['chord']
    @modifier = raw['modifier']
    @data = Hash[strings.map { |s| [s, raw[s] || '0'] }]
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

  def self.db
    @db ||= connect
  end

  def self.find_chords(q, instrument)
    query = {} if q == 'all'
    query ||= Hash[
      q.to_s.split('--').first.scan(/([a-zA-Z])(\d+)/) # [['e', '5'], ['b', '6']]
    ]
    db[instrument].find(query).map { |result| GuitarChord.new(result) }
  end

  def self.insert(instrument, data)
    db[instrument].insert(data)
  end
end

ChordDB.connect

get '/' do
  haml :index
end

get '/guitar/:q.json' do
  ChordDB.find_chords(params['q'], 'guitar').
    to_json
end

get '/guitar/:q' do
  @chords = ChordDB.find_chords(params['q'], 'guitar')
  haml :chords
end
