require 'sinatra'
require 'mongo'
require 'haml'
require 'json'

class GuitarChord
  def strings
    ['E', 'A', 'D', 'g', 'b', 'e'].reverse
  end

  attr_reader :name, :data

  def initialize(raw)
    @name = raw['name']
    @data = Hash[strings.map { |s| [s, raw[s] || '0'] }]
  end

  def url
    "http://chordsearch.heroku.com/guitar/#{key}"
  end

  def key
    strings.map { |s| [s, data[s]] }.flatten.join <<
      '--' << name.gsub(/\s+/, '_')
  end

  def to_json(*args)
    {
      "instrument" => "guitar",
      "name"       => name,
      "url"        => url,
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
    query = Hash[
      q.to_s.scan(/([a-zA-Z])(\d+)/) # [['e', '5'], ['b', '6']]
    ]
    db[instrument].find(query).map { |result| GuitarChord.new(result) }
  end
end

ChordDB.connect

get '/' do
  "fuck yeah chord search!"
end

get '/guitar/search/:q.json' do
  ChordDB.find_chords(params['q'], 'guitar').
    to_json
end

get '/guitar/search/:q' do
  @chords = ChordDB.find_chords(params['q'], 'guitar')
  haml :chords
end
