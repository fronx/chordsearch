require 'sinatra'
require 'haml'
require 'json'
require 'cgi'

set :app_file, __FILE__
enable :static

require './lib/chord'
require './lib/instruments'
require './lib/chord_db'
require './lib/chord_collection'

get '/' do
  haml :index
end

get %r{^/(\w+)$} do |instrument|
  redirect "/#{instrument}/"
end

get %r{^/collection/([^/]+)/?$} do |collection|
  @collection = ChordCollection.find(collection)
end

get %r{^/(\w+)/$} do |instrument|
  redirect '/' unless ChordDB[instrument]
  @query = {}
  @search_chord = ChordDB[instrument].new
  @chords = []
  @collection = collection
  haml :chords
end

get %r{^/(\w+)/(.*\.json)$} do |instrument, q|
  query = ChordDB.query_from_param(q)
  ChordDB.find_chords(query, instrument).to_json
end

get %r{^/(\w+)/([^/]+)/add/([^/]+)/(.*)$} do |instrument, q, collection, chord_key|
  @collection = ChordCollection.find(collection) || ChordCollection.new('name' => collection)
  @collection << chord_key
  @collection.save
  redirect "/#{instrument}/#{q}?c=#{collection}"
end

get %r{^/(\w+)/(.*)$} do |instrument, q|
  @query = ChordDB.query_from_param(q)
  @search_chord = ChordDB[instrument].search_chord(@query)
  @chords = ChordDB.find_chords(@query, instrument)
  @collection = collection
  haml :chords
end

def collection
  if params['c']
    ChordCollection.find(params['c']) ||
      ChordCollection.new('name' => params['c'])
  end
end
