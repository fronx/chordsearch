# chord search
    in:  partial chord  as json
    out: list of chords as json

## search request
    {
      "instrument": "guitar",
      "tones"     : { "e": 5, "h": 5, "g": 6 }
    }

## search via url
    http://chordsearch.heroku.com/guitar/search/e5h5g6

## response
    [
      {
        "instrument": "guitar",
        "name"      : "A major",
        "url"       : "http://chordsearch.heroku.com/guitar/A-major/e5h5g6D7A7E5",
        "tones"     : { "e": 5, "h": 5, "g": 6, "D": 7, "A": 7, "E": 5 }
      },
      {
        // other chord that matches the search request
      }
    ]

## data storage
- mongodb?
- bucket: instrument
  - record: chord
- indexes
  - sets of chords by string + fret
  - search via multiple set intersection

## chord recognizer
    in:  audio recording
    out: chord as json
