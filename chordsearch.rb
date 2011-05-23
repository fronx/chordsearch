require 'sinatra'
require 'mongo'
require 'haml'

def connect_mongo
  uri = URI.parse(ENV['MONGOHQ_URL'])
  conn = Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
  conn.db(uri.path.gsub(/^\//, ''))
end

db = connect_mongo

class GuitarChord
  def strings
    ['E', 'A', 'D', 'g', 'b', 'e'].reverse
  end

  attr_reader :name, :data

  def initialize(raw)
    @name = raw['name']
    @data = Hash[strings.map { |s| [s, raw[s] || '0'] }]
  end
end

get '/' do
  "fuck yeah chord search!"
end

get '/guitar/search/:q' do
  query = Hash[
    params['q'].to_s.
    scan(/([a-zA-Z])(\d+)/) # [['e', '5'], ['b', '6']]
  ]
  @chords = db['guitar'].find(query).map { |result| GuitarChord.new(result) }
  haml :chords
end
