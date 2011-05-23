# chord search
    in:  partial chord as a list of string/fret pairs
    out: list of chords as json

## search via url
- [http://chordsearch.heroku.com/guitar/e5D7.json](http://chordsearch.heroku.com/guitar/e5D7.json)
- [http://chordsearch.heroku.com/guitar/e5D7](http://chordsearch.heroku.com/guitar/e5D7) (for html)

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
- mongodb
- one collection per instrument
- chords are stored as `{ "name": "A major", "e": "5", "b": "5", "g": "6", "D": "7", "A": "7", "E": "5" }`

# future extensions

## audio chord recognizer
    in:  audio recording
    out: chord as json

## pictures
- display chords as nice images

## audio output
- record string samples
- store them on soundcloud
- play a sample for each string (samples must be equally trimmed!)
- make succession speed adjustable

## user data
- input of chord tabs (succession of chords)
- users can "like" a chord tab
