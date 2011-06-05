module ChordDB
  def self.find_chords(query, instrument)
    chords = ENV['NOINTERNET'] ? [chord_class(instrument).dummy] :
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

  def self.query_from_param(q)
    query = {} if q == 'all'
    query ||= Hash[
      q.to_s.split('--').first.scan(/([a-zA-Z])(\d+)/) # [['e', '5'], ['b', '6']]
    ] # {'e' => '5', 'b' => '6'}
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

  def self.insert(instrument, data)
    db[instrument].insert(data)
  end

  def self.db
    @db ||= connect
  end

  def self.connect
    uri = URI.parse(ENV['MONGOHQ_URL'])
    conn = Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
    @db = conn.db(uri.path.gsub(/^\//, ''))
  end
end
