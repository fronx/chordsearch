window.chordPlayers = [];

chordPlayers.stop = function() {
  window.clearTimeout(this.timeoutID);
  chordPlayers.timeoutID = null;
  $.each(this, function() { this.api_stop(); });
};
chordPlayers.stringCount = function() {
  return parseInt($('#chord-player').attr('cp-string-count'));
};
chordPlayers.add = function(player) {
  this.push(player);
  this.sort(function(a, b) {
    var compA = a.name.toUpperCase();
    var compB = b.name.toUpperCase();
    return (compA > compB) ? -1 : (compA < compB) ? 1 : 0;
  });
  if (this.length == this.stringCount()) {
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
chordPlayers.bufferedTrack = {};
chordPlayers._play = function(player, toneKey) {
  var fret = toneKey.match(/([a-z])(\d+)/i)[2]; // ["e2", "e", "2"] --> "2"
  player.api_skip(fret);
  player.api_seekTo(0);
  player.api_play();
};
chordPlayers.bufferTrack = function(toneKey) {
  if (!chordPlayers.bufferedTrack[toneKey]) {
    var player = this.playerFromToneKey(toneKey);
    player.api_setVolume(0);
    chordPlayers._play(player, toneKey);
  };
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
  this.stop();
  if (this.chordBuffered(this.chordKey)) {
    $.each(this.chordKeyToToneKeys(this.chordKey), function(index) {
      var toneKey = this;
      var player = chordPlayers.playerFromToneKey(this);
      window.setTimeout(function() {
        player.api_setVolume(100);
        chordPlayers._play(player, toneKey);
      }, 50 * index);
    });
  } else {
    console.log('not buffered yet: ' + this.chordKey);
    $.each(this.chordKeyToToneKeys(this.chordKey), function() {
      chordPlayers.bufferedTrack[this] ||
        chordPlayers.bufferTrack(this), allBuffered = false;
    });
    if (chordPlayers.poller == null) {
      chordPlayers.poller = window.setInterval(function(){
        if (chordPlayers.chordBuffered(chordPlayers.chordKey)) {
          window.clearInterval(chordPlayers.poller);
          chordPlayers.poller = null;
          chordPlayers.play();
        }
      }, 500);
    }
  }
};
chordPlayers.toneKeyFromPlayer = function(player) {
  string = player.name.split('_').reverse()[0];
  fret = player.api_getCurrentTrackIndex();
  return string + fret;
};

soundcloud.addEventListener('onPlayerReady', function(player, data) {
  chordPlayers.add(player);
  console.log("ready: " + player.name);
});
soundcloud.addEventListener('onMediaDoneBuffering', function(player, data) {
  player.api_stop();
  chordPlayers.bufferedTrack[chordPlayers.toneKeyFromPlayer(player)] = true;
});
soundcloud.addEventListener('onMediaPlay', function(player, data) {
  if (chordPlayers.timeoutID == null) {
    chordPlayers.timeoutID = window.setTimeout(function() { chordPlayers.stop() }, 4000);
  }
});
$('.play-chord').live('click', function() {
  chordPlayers.play(this);
  return false;
});
