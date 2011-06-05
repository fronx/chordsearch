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

  def self.string_sets
    strings.map do |string|
      SoundCloud.set_url('fronx', "mandolin-string-#{string}")
    end
  end
end
