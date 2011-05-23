# chord search
    in:  partial chord as a list of string/fret pairs
    out: list of chords as json

## search via url
- [http://chordsearch.heroku.com/guitar/e5D7.json](http://chordsearch.heroku.com/guitar/e5D7.json)
- [http://chordsearch.heroku.com/guitar/e5D7](http://chordsearch.heroku.com/guitar/e5D7) (for html)

## html output
chords are displayed as pictures thanks to [theophani](https://github.com/theophani)'s [styling](https://github.com/theophani/Flashchords/blob/master/fc/css/style.css).

## json response
    [
      {
        "instrument": "guitar",
        "chord"     : "A",
        "modifier"  : "major",
        "url_html"  : "http://chordsearch.heroku.com/guitar/e5h5g6D7A7E5--A_major",
        "url_json"  : "http://chordsearch.heroku.com/guitar/e5h5g6D7A7E5--A_major.json",
        "tones"     : {
          "e": 5,
          "b": 5,
          "g": 6,
          "D": 7,
          "A": 7,
          "E": 5
        }
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

## visual input
- search chords by clicking on a graphical fretboard

## audio input
    in:  audio recording
    out: chord as json

## audio output
- record string samples
- store them on soundcloud
- play a sample for each string (samples must be equally trimmed!)
- make succession speed adjustable

## user data
- input of chord tabs (succession of chords)
- users can "like" a chord tab
