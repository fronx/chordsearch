window.chordPlayers = [];

chordPlayers.stop = function() {
  $('.play-chord').removeClass('loading');
  $.each(this, function() { this.api_stop(); });
};

chordPlayers.stringCount = (function() {
  return parseInt($('#chord-player').attr('cp-string-count'));
}());

chordPlayers.add = function(player) {
  this.push(player);
  this.sort(function(a, b) {
    var compA = a.name.toUpperCase();
    var compB = b.name.toUpperCase();
    return (compA < compB) ? -1 : (compA > compB) ? 1 : 0;
  });
  if (this.length == this.stringCount) {
    $('.play-chord').show();
  };
};

chordPlayers.playerFromToneKey = function(toneKey) {
  var string = toneKey.match(/([a-z])(\d+)/i)[1];  // ["e2", "e", "2"] --> "e"
  var players = chordPlayers.filter(function(item){
    return item.name.split('_').reverse()[0] == string;
  });
  return players[0];
};

chordPlayers.init = function(player, toneKey) {
  var fret = toneKey.match(/([a-z])(\d+)/i)[2]; // ["e2", "e", "2"] --> "2"
  console.log('init: ' + toneKey);
  player.api_setVolume(0);
  player.api_skip(fret);
  player.api_seekTo(0);
};

chordPlayers.bufferedTrack = {};

chordPlayers.bufferTrack = function(toneKey) {
  if (!chordPlayers.bufferedTrack[toneKey]) {
    var player = this.playerFromToneKey(toneKey);
    chordPlayers.init(player, toneKey);
    player.api_play();
  };
};

chordPlayers.doneBuffering = function(player) {
  player.api_stop();
  this.bufferedTrack[this.toneKeyFromPlayer(player)] = true;
  console.log('onMediaDoneBuffering');
};

chordPlayers.chordBuffered = function(chordKey) {
  var allBuffered = true;
  $.each(this.chordKeyToToneKeys(chordKey), function() {
    chordPlayers.bufferedTrack[this] || (allBuffered = false);
  });
  return allBuffered;
};

chordPlayers.poller = null;

chordPlayers.play = function(playLink) {
  if (playLink != undefined) {
    this.chordKey = $(playLink).attr('href');
  };

  this._forgetBufferStates();

  if (this.chordBuffered(this.chordKey)) {
    this._play();
  } else {
    this._buffer();
    this._wait();
  }
};

chordPlayers._forgetBufferStates = function() {
  $.each(Object.keys(chordPlayers.bufferedTrack), function() {
    if (chordPlayers.chordKeyToToneKeys(chordPlayers.chordKey).indexOf('' + this) == -1) {
      chordPlayers.bufferedTrack[this] = null;
    }
  });
};

chordPlayers._play = function() {
  window.clearTimeout(this.timeoutID);
  this.timeoutID = null;

  $.each(this.chordKeyToToneKeys(this.chordKey), function(index) {
    var toneKey = this;
    var player = chordPlayers.playerFromToneKey(this);
    player.api_stop();
    player.api_setVolume(100);

    window.setTimeout(function() {
      player.api_play();
    }, 50 * (index + 10));
  });

  // stop
  chordPlayers.timeoutID = window.setTimeout(function() {
    console.log('timeout!');
    chordPlayers.stop();
  }, 3000);
};

chordPlayers._buffer = function() {
  $.each(this.chordKeyToToneKeys(this.chordKey), function() {
    chordPlayers.bufferedTrack[this] ||
      chordPlayers.bufferTrack(this), allBuffered = false;
  });
};

chordPlayers._wait = function() {
  if (chordPlayers.poller == null) {
    chordPlayers.poller = window.setInterval(function(){
      if (chordPlayers.chordBuffered(chordPlayers.chordKey)) {
        window.clearInterval(chordPlayers.poller);
        chordPlayers.poller = null;
        chordPlayers.play();
      }
    }, 50);
  }
};

chordPlayers.chordKeyToToneKeys = function(chordKey) {
  return chordKey           // #e0b1g2D2A0Ex--A_minor
    .replace('#', '')       // e0b1g2D2A0Ex--A_minor
    .split('--')[0]         // e0b1g2D2A0Ex
    .split(/([a-zA-Z]\d+)/) // ["", "e0", "", "b1", "", "g2", "", "D2", "", "A0", "Ex"]
    .filter(function(item){ // [e0", b1", g2", D2", A0"]
      return item.match(/([a-zA-Z]\d+)/);
    });
};

chordPlayers.toneKeyFromPlayer = function(player) {
  string = player.name.split('_').reverse()[0];
  fret = player.api_getCurrentTrackIndex();
  return string + fret;
};

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
