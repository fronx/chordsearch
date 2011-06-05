require 'mongo'

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

  def self.chromatic_scale
    ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
  end

  def self.chromatic_index(tone)
    chromatic_scale.index(tone.upcase)
  end

  def self.max_fret
    12
  end

  attr_reader :chord, :modifier, :data

  def initialize(raw = {})
    @chord = raw['chord']
    @modifier = raw['modifier']
    @raw = raw.slice(*strings)
    @data = Hash[
      strings.reverse.map do |s|
        if raw[s] == 'x'
          fret = 'x'
        else
          fret = raw[s].to_i
          fret -= 12 if fret > self.class.max_fret
        end
        [s, fret.to_s]
      end
    ]
  end

  def path_html
    "#{self.class.instrument}/#{key}"
  end

  def url_html
    "http://chordsearch.heroku.com/#{path_html}"
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

  def tone(string, fret=nil)
    fret ||= data[string]
    return nil if fret == 'x'
    index = self.class.chromatic_index(string) + fret.to_i
    index -= 12 while index > 11
    self.class.chromatic_scale[index]
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
