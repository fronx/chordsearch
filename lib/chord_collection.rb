class ChordCollection
  def self.db() ChordDB.db['chord_collection'] end
  def db() self.class.db end

  def self.create(name)
    db.insert('name' => name)
    find(name)
  end

  def self.find(name)
    record = db.find('name' => name).first
    new(record) if record
  end

  attr_reader :name

  def initialize(data)
    @id = data['_id']
    @name = data['name']
    @chords = data['chords'] || []
  end

  def <<(chord_key)
    @chords << chord_key
  end

  def chords
    @chords.map do |chord|
      instrument, chord_key = chord.split('/') # "guitar/E0A2D0g0b0e3--E_m7"
      query = ChordDB.query_from_param(chord_key)
      ChordDB.find_chords(query, instrument)
    end.flatten
  end

  def save
    if @id
      db.update({"_id" => @id},
        {"$set" => {"chords" => @chords}
      })
    else
      @id = db.insert('name' => name, 'chords' => @chords)
    end
  end
end
