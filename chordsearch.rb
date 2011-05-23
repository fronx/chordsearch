require 'sinatra'

def connect_mongo
  uri = URI.parse(ENV['MONGOHQ_URL'])
  conn = Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
  conn.db(uri.path.gsub(/^\//, ''))
end

db = connect_mongo

get '/' do
  "fuck yeah chord search!"
end

get '/guitar/search/:q' do
  db['guitar'].find({tones: {e: 5, h: 5}}).map { |r| r.to_s }
end
