window.chordPlayers = [];

(function(){

  var timeoutID;
  var chordKey;

  var stringCount = (function() {
    return parseInt($('#chord-player').attr('cp-string-count'));
  }());

  var playerFromToneKey = function(toneKey) {
    var string = toneKey.match(/([a-z])(\d+)/i)[1];  // ["e2", "e", "2"] --> "e"
    var players = chordPlayers.filter(function(item){
      return item.name.split('_').reverse()[0] == string;
    });
    return players[0];
  };

  var init = function(player, toneKey) {
    var fret = toneKey.match(/([a-z])(\d+)/i)[2]; // ["e2", "e", "2"] --> "2"
    console.log('init: ' + toneKey);
    player.api_setVolume(0);
    player.api_skip(fret);
    player.api_seekTo(0);
  };

  var bufferedTrack = {};

  var bufferTrack = function(toneKey) {
    if (!bufferedTrack[toneKey]) {
      var player = playerFromToneKey(toneKey);
      init(player, toneKey);
      player.api_play();
    };
  };

  var chordBuffered = function(chordKey) {
    var allBuffered = true;
    $.each(chordKeyToToneKeys(chordKey), function() {
      bufferedTrack[this] || (allBuffered = false);
    });
    return allBuffered;
  };

  var poller = null;

  var _forgetBufferStates = function() {
    $.each(Object.keys(bufferedTrack), function() {
      if (chordKeyToToneKeys(chordKey).indexOf('' + this) == -1) {
        bufferedTrack[this] = null;
      }
    });
  };

  var _play = function() {
    window.clearTimeout(timeoutID);
    timeoutID = null;

    $.each(chordKeyToToneKeys(chordKey), function(index) {
      var toneKey = this;
      var player = playerFromToneKey(this);
      player.api_stop();
      player.api_setVolume(100);

      window.setTimeout(function() {
        player.api_play();
      }, 50 * (index + 10));
    });

    // stop
    timeoutID = window.setTimeout(function() {
      console.log('timeout!');
      chordPlayers.stop();
    }, 3000);
  };

  var _buffer = function() {
    $.each(chordKeyToToneKeys(chordKey), function() {
      bufferedTrack[this] ||
        bufferTrack(this), allBuffered = false;
    });
  };

  var _wait = function() {
    if (poller == null) {
      poller = window.setInterval(function(){
        if (chordBuffered(chordKey)) {
          window.clearInterval(poller);
          poller = null;
          play();
        }
      }, 50);
    }
  };

  var chordKeyToToneKeys = function(chordKey) {
    return chordKey           // #e0b1g2D2A0Ex--A_minor
      .replace('#', '')       // e0b1g2D2A0Ex--A_minor
      .split('--')[0]         // e0b1g2D2A0Ex
      .split(/([a-zA-Z]\d+)/) // ["", "e0", "", "b1", "", "g2", "", "D2", "", "A0", "Ex"]
      .filter(function(item){ // [e0", b1", g2", D2", A0"]
        return item.match(/([a-zA-Z]\d+)/);
      });
  };

  var toneKeyFromPlayer = function(player) {
    string = player.name.split('_').reverse()[0];
    fret = player.api_getCurrentTrackIndex();
    return string + fret;
  };

  var add = function(player) {
    this.push(player);
    this.sort(function(a, b) {
      var compA = a.name.toUpperCase();
      var compB = b.name.toUpperCase();
      return (compA < compB) ? -1 : (compA > compB) ? 1 : 0;
    });
    if (this.length == stringCount) {
      $('.play-chord').show();
    };
  };

  var doneBuffering = function(player) {
    player.api_stop();
    bufferedTrack[toneKeyFromPlayer(player)] = true;
    console.log('onMediaDoneBuffering');
  };

  var stop = function() {
    $('.play-chord').removeClass('loading');
    $.each(this, function() { this.api_stop(); });
  };

  var play = function(playLink) {
    if (playLink != undefined) {
      chordKey = $(playLink).attr('href');
    };

    _forgetBufferStates();

    if (chordBuffered(chordKey)) {
      _play();
    } else {
      _buffer();
      _wait();
    }
  };

  chordPlayers.add = add;
  chordPlayers.doneBuffering = doneBuffering;
  chordPlayers.stop = stop;
  chordPlayers.play = play;

}());

// - - - - - - - - - - - - - - - - - - - - - - -

soundcloud.addEventListener('onPlayerReady', function(player, data) {
  chordPlayers.add(player);
});

soundcloud.addEventListener('onMediaDoneBuffering', function(player, data) {
  chordPlayers.doneBuffering(player)
});

$('.play-chord').live('click', function() {
  chordPlayers.stop();
  $(this).addClass('loading');
  chordPlayers.play(this);
  return false;
});
