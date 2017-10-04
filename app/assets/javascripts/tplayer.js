/* Pop Up Archive embedded transcript/player
   Copyright 2014 Pop Up Archive
   Licensed under the MIT License
*/

"use strict"

var PUATPlayer = function(opts) {
  // parse opts
  if (!opts.fileId) {
    throw new Error("fileId required");
  }
  if (!opts.jplayer) {
    throw new Error("jplayer required");
  }
  this.fileId  = opts.fileId;
  this.jplayer = opts.jplayer;

  // create waveform
  // this.generateWaveform();
  this.el      = $('#jp_container-' + this.fileId);
  // this.element = this.el.find('.scrubber canvas')[0];
  this.jp_pbar = this.el.find('.jp-progress');

  if (opts.wfHeight) {
    this.wfHeight = opts.wfHeight;
  }

  if (!opts.duration) {
    //console.log(this.el);
    this.time    = parseInt(this.el.find('.jp-time-holder .jp-current-time').html());
    //console.log(this.time);
    this.ms      = this.el.find('.jp-time-holder .jp-duration').html().split(':');
    this.duration = parseInt(this.ms[0]*60) + parseInt(this.ms[1]);
  }

  // this.context = this.element.getContext('2d');
  // this.mapped  = this.mapToArray(this.wavformData, this.el.width());
  // this.el.find('.jp-progress .calculating').addClass('hidden');
  // this.draw();
  // this.jp_seek_bar = this.el.find('.jp-progress .jp-seek-bar');
  // var img = this.element.toDataURL();
  // this.jp_seek_bar.css("background", 'url('+img+') no-repeat');
  // redraw the canvas in different color for the progressive play bar
  // this.draw('rgb(255, 190, 48)');
  // img = this.element.toDataURL();
  // this.jp_play_bar = this.el.find('.jp-progress .jp-play-bar');
  // this.jp_play_bar.css("background", 'url('+img+') no-repeat');

  // setup
  this.setListeners();
  this.bindEvents();

  if (opts.play) {
    if ($.isNumeric(opts.play.start)) {
      // playHead only takes a percentage of duration, which can be inaccurate.
      if (opts.play.now) {
        $(this.jplayer).jPlayer('play', opts.play.start);
      }
      else {
        $(this.jplayer).jPlayer('pause', opts.play.start);
      }
    }
    if (opts.play.end) {
      this.hardStop = opts.play.end;
    }
  }
};

PUATPlayer.prototype = {
  secsToHMS: function(secs) {
    var sec_num = parseInt(secs, 10); // don't forget the second param
    var hours   = Math.floor(sec_num / 3600);
    var minutes = Math.floor((sec_num - (hours * 3600)) / 60);
    var seconds = sec_num - (hours * 3600) - (minutes * 60);

    if (hours   < 10) {hours   = "0"+hours;}
    if (minutes < 10) {minutes = "0"+minutes;}
    if (seconds < 10) {seconds = "0"+seconds;}
    var hms    = hours+':'+minutes+':'+seconds;
    return hms;
  },

  setListeners: function() {
    var self = this;
    var adapter = new playerjs.JPlayerAdapter($(self.jplayer));
    adapter.ready();
    $("#jp-reverse-button-"+self.fileId).on('click', function() {
      $(self.jplayer).jPlayer('playHead', 0);
    });
    $('#pua-tplayer-'+self.fileId+'-transcript .pua-tplayer-text .text').click(function() {
      var clicked = this;
      var offset  = parseInt( $(clicked).parent().data('offset') );
      //console.log('clicked on text with id', clicked.id, offset);
      $(self.jplayer).jPlayer('play', offset);
    });
    $('#pua-tplayer-'+self.fileId+'-transcript .pua-tplayer-text').hover(
      function() { $(this).addClass('hover'); },
      function() { $(this).removeClass('hover'); }
    );
    // jplayer seems to have a side-effect where all <a> links within its
    // jp-interface block are disabled. This re-enables them.
    $('.jp-gui.jp-interface a').click(function(ev) {
      ev.stopPropagation();
      var tar = $(ev.relatedTarget);
      window.location = tar.attr('href');
    });
    self.autoScroll = true;
  },

  bindEvents: function() {
    var self = this;
    $(self.jplayer).bind($.jPlayer.event.timeupdate, function(ev) {
      if (self.autoScroll === true) {
        self.scrollOnPlay(ev);
      }
    });
    $(".ts-search input").keyup(function() {
      if ($(this).val()) {
        $(".clear-find").show();
        $(".search-submit").prop("disabled", false);
      } else {
        $(".clear-find").hide();
        $(".search-submit").prop("disabled", true);
      }
    });
    $(self.jplayer).bind($.jPlayer.event.seeking, function(ev) {
      //console.log('seeking');
      $('#pua-tplayer-'+self.fileId+'-transcript thead').addClass('loading-overlay');
      $('#pua-tplayer-'+self.fileId+'-transcript .loading-indicator').toggleClass('hidden');
    });
    $(self.jplayer).bind($.jPlayer.event.seeked, function(ev) {
      //console.log('seeked');
      $('#pua-tplayer-'+self.fileId+'-transcript thead').removeClass('loading-overlay');
      $('#pua-tplayer-'+self.fileId+'-transcript .loading-indicator').toggleClass('hidden');
      self.scrollOnSeek(ev);
    });
    $(".clear-find").on("click", function() {
      self.searchTerm = "";
      $(".ts-search input").val("");
      $(".transcript").removeHighlight();
      $(".ts-find-hit").remove();
      self.autoScroll = true;
      $(".result-numbers").html("");
      $(this).hide();
    });
    $(".ts-search").on("submit", function(e) {
      e.preventDefault();
      self.autoScroll = false;
      var lastButton = $(this).parent().find(".last-result");
      var nextButton = $(this).parent().find(".next-result");
      if ($(this).find("input").val() == self.searchTerm) {
        $(nextButton).trigger("click");
      } else {
        self.searchTerm = $(this).find("input").val();
        var transcript = $(this).siblings(".tplayer").find(".transcript");
        $(this).parent().find(".next-result, .last-result").addClass("inactive");
        transcript.removeHighlight();
        if ( self.searchTerm ) {
          transcript.highlight( self.searchTerm );
        }
        self.highlightCounter = 0;
        self.position = 0;
        var highlightSpans = $(transcript).find("span.highlight");
        // Reset from last search
        $(nextButton).unbind("click");
        $(lastButton).unbind("click");
        // Only bind if there are hits
        if (highlightSpans.length > 0) {
          $(nextButton).removeClass("inactive");
          $(nextButton).bind("click", function() {
            if (highlightSpans.length > self.highlightCounter) {
              var nextHighlight = $(highlightSpans)[self.highlightCounter];
              var target = $(nextHighlight).parents(".pua-tplayer-text");
              self.scrollToLine(target, true);
              self.highlightCounter ++;
              if (self.highlightCounter > 1) {
                $(lastButton).removeClass("inactive");
              }
              if (highlightSpans.length === self.highlightCounter) {
                $(nextButton).addClass("inactive");
              }
              $(".result-numbers").html("<div>"+self.highlightCounter+" of "+highlightSpans.length+" hits</div>");
            }
          });
          $(lastButton).bind("click", function() {
            if (self.highlightCounter > 1) {
              self.highlightCounter --;
              var lastHighlight = $(highlightSpans)[self.highlightCounter-1];
              var target = $(lastHighlight).parents(".pua-tplayer-text");
              self.scrollToLine(target, true);
              if (self.highlightCounter == 1) {
                $(lastButton).addClass("inactive");
              }
              if (highlightSpans.length > self.highlightCounter) {
                $(nextButton).removeClass("inactive");
              }
              $(".result-numbers").html("<div>"+self.highlightCounter+" of "+highlightSpans.length+" hits</div>");
            }
          });
          // Scroll to first result
          if (self.highlightCounter === 0) {
            $(nextButton).trigger("click");
          }
        self.addScrubberHits(highlightSpans);
        } else {
          $(".result-numbers").html("<div>No hits</div>");
        }
      }
    });
    var modalId = 'share-modal-'+self.fileId;
    $('#'+modalId).on('show.bs.modal', function (ev) {
      if (!ev.relatedTarget) {
        console.log("cannot find clicked button for modal:", ev);
        return;
      }
      var button = $(ev.relatedTarget);
      var row    = button.parents('.pua-tplayer-text');
      var ttbl   = button.parents('.tplayer.scrolling');
      var offset = row.data('offset');
      var itemId = ttbl.data('perm');
      var collId = ttbl.data('coll');
      var idx    = parseInt(row.data("idx"), 10);
      var modal  = $(this);
      var hms    = self.secsToHMS(offset);
      var lnk    = window.shortURL + '/t/' + itemId;
      var lnkWithOffset = lnk + '/' + offset;
      var tweetStr = row.find(".text").html().trim();
      console.log('row', row, 'ttbl', ttbl, 'modal', modal, 'lnk', lnk, 'hms', hms);
      console.log('tweetStr', tweetStr);
      if ($(".pua-tplayer-text[data-idx='"+(idx+1)+"']").length !== 0) {
        tweetStr += " " + $(".pua-tplayer-text[data-idx='"+(idx+1)+"']").find(".text").html().trim();
      }
      if ($(".pua-tplayer-text[data-idx='"+(idx+2)+"']").length !== 0) {
        tweetStr += " " + $(".pua-tplayer-text[data-idx='"+(idx+2)+"']").find(".text").html().trim();
      }
      var escTxt         = tweetStr.replace(/<.+?>/g, '');
      modal.find(".share-link").html(lnk);
      modal.find(".share-text").val(escTxt);
      modal.find("label[for='timestamp']").html("&nbspStart at:&nbsp"+hms);
      modal.find(".share-text").on("keyup", function() {
        escTxt = modal.find(".share-text").val();
        var tweetLink = "https://twitter.com/share/?url="+lnk+"&via="+twitter_user+"&text="+escTxt;
        modal.find(".share-button").attr("href", tweetLink);
        var chars = escTxt.length;
        modal.find(".chars").html(chars);
        if (chars >= 140) {
          modal.find(".chars").addClass("too-many-chars");
        } else {
          modal.find(".chars").removeClass("too-many-chars");
        }
      });
      modal.find("input[name='timestamp']").on("change", function() {
        if ($(this).is(":checked")) {
          modal.find(".share-link").html(lnk);
          //modal.find(".share-link").html(lnkWithOffset);
        } else {
          modal.find(".share-link").html(lnk);
        }
      });
      modal.find(".share-text").trigger("keyup");
      modal.find("input[name='timestamp']").trigger("change");
    });
  },

  scrollOnPlay: function(ev) {
    var self = this;
    var curOffset = Math.floor( ev.jPlayer.status.currentTime );
    // if the current offset matches a text id, select the text
    var target = $('#pua-tplayer-text-'+self.fileId+'-'+curOffset);
    //console.log('play:', ev.jPlayer.status.currentTime, curOffset, target);
    if (target && target.length) {
      self.scrollToLine(target, false);
    }
    if (self.hardStop && curOffset >= self.hardStop) {
      $(self.jplayer).jPlayer('stop');
    }
  },

  scrollToLine: function(target, find) {
    var self = this;
    if (target && target.length && !target.hasClass('selected')) {
      //console.log('scrolling to line');
      if (!find) {
        // de-select any currently selected first
        var curSelected = $("#pua-tplayer-"+self.fileId+"-transcript .pua-tplayer-text.selected");
        curSelected.removeClass('selected');
        // select new target
        target.addClass('selected');
      }
      // scroll
      var scrollMath = {};
      scrollMath.pxBefore = 20;
      scrollMath.lineNum  = parseInt( target.data('idx') );
      var tgtWrap = $("#pua-tplayer-"+self.fileId+"-transcript.scrolling .body");
      scrollMath.simple = tgtWrap.scrollTop() - tgtWrap.offset().top + target.offset().top - scrollMath.pxBefore;
      //console.log('scrollMath: ', scrollMath);
      tgtWrap.parent().animate({ scrollTop: scrollMath.simple }, 200);
    }
    //console.log('scrollToLine', target, target.length, target.hasClass('selected'));
  },

  scrollOnSeek: function(ev) {
    //console.log('seek finished');
    var self = this;
    var curOffset = Math.floor( ev.jPlayer.status.currentTime );
    // find nearest target
    var target = self.findNearestLine(curOffset);
    //console.log('seek:', curOffset, target);
    self.scrollToLine(target);
  },

  findNearestLine: function(offset) {
    // look for a target matching offset, working backward till we find one.
    var self = this;
    var target = $('#pua-tplayer-text-'+self.fileId+'-'+offset);
    //console.log('looking for line nearest to', offset);
    while (!target.length) {
      offset--;
      target = $('#pua-tplayer-text-'+self.fileId+'-'+offset);
      if (offset <= 0) { break; }
    }
    //console.log('nearest line:', offset, target);
    return target;
  },

  // waveformData: [],

  // waveform: function() {
  //   return this.waveformData;
  // },

  // generateWaveform: function() {
  //   this.waveformData.length = 0;
  //   var l = 0;
  //   var segments = parseInt(Math.random() * 1000 + 1000);

  //   for (var i=0; i < segments; i++) {
  //     l = this.waveformData[i] = Math.max(Math.round(Math.random() * 10) + 2, Math.min(Math.round(Math.random() * -20) + 50, Math.round(l + (Math.random() * 25 - 12.5))));
  //   }
  // },

  // canvasWidth: function() {
  //   return this.jp_pbar.width();
  // },

  // canvasHeight: function() {
  //   if (this.wfHeight) return this.wfHeight;
  //   return this.jp_pbar.height();
  // },

  // barTop: function(size, height) {
  //   return Math.round((50 - size) * (height / 50) * 0.5);
  // },

  // barHeight: function(size, height) {
  //   return Math.round(size * (height / 50));
  // },

  // mapToArray: function(waveform, size) {
  //   var currentPixel = 0;
  //   var currentChunk = 0;
  //   var waveform = this.waveformData;
  //   var chunksPerPixel = waveform.length / size;
  //   var chunkStart, chunkEnd, sum, j;
  //   var array = [];
  //   while (currentPixel < size) {
  //     chunkStart = Math.ceil(currentChunk);
  //     currentChunk += chunksPerPixel;
  //     chunkEnd = Math.floor(currentChunk);

  //     sum = 0;
  //     for (j = chunkStart; j <= chunkEnd; j += 1) {
  //       sum += waveform[j];
  //     }

  //     array[currentPixel] = sum / (chunkEnd - chunkStart + 1);
  //     currentPixel += 1;
  //   }
  //   return array;
  // },

  // draw: function(color) {
  //   var height = this.canvasHeight();
  //   //console.log('canvas is ' + height + 'px tall');
  //   var width  = this.mapped.length;
  //   this.element.width = width;
  //   this.element.height = height;
  //   var scrubberEnd = Math.round(width * this.time / this.duration) || 0;
  //   //console.log('scrubberEnd=', scrubberEnd, 'width=', width, 'height=', height);
  //   this.context.clearRect(0, 0, width + 200, height + 200);
  //   if (color) {
  //     this.context.fillStyle = color;
  //   }
  //   else {
  //     this.context.fillStyle = 'rgb(255, 190, 48)';
  //   }
  //   for (var i = 0; i < width; i++) {
  //     if (i == scrubberEnd && !color) {
  //       this.context.fillStyle = "rgb(187, 187, 187)";
  //     }
  //     this.context.fillRect(i, this.barTop(this.mapped[i], height), 1, this.barHeight(this.mapped[i], height));
  //   }
  // }
    addScrubberHits: function(highlightSpans) {
      var self = this;
      $(".ts-find-hit").remove();
      $(highlightSpans).each(function() {
        var offset = $(this).parents(".pua-tplayer-text").data("offset");
        var position = offset/self.duration *100;
        $(".jp-seek-bar").append("<div class='ts-find-hit' style='left:"+Math.floor(position)+"%'></div>");
      });
    }

};

jQuery.fn.highlight = function(pat) {
 function innerHighlight(node, pat) {
  var skip = 0;
  if (node.nodeType == 3) {
   var pos = node.data.toUpperCase().indexOf(pat);
   if (pos >= 0) {
    var spannode = document.createElement('span');
    spannode.className = 'highlight';
    var middlebit = node.splitText(pos);
    var endbit = middlebit.splitText(pat.length);
    var middleclone = middlebit.cloneNode(true);
    spannode.appendChild(middleclone);
    middlebit.parentNode.replaceChild(spannode, middlebit);
    skip = 1;
   }
  }
  else if (node.nodeType == 1 && node.childNodes && !/(script|style)/i.test(node.tagName)) {
   for (var i = 0; i < node.childNodes.length; ++i) {
    i += innerHighlight(node.childNodes[i], pat);
   }
  }
  return skip;
 }
 return this.each(function() {
  innerHighlight(this, pat.toUpperCase());
 });
};

jQuery.fn.removeHighlight = function() {
 function newNormalize(node) {
    for (var i = 0, children = node.childNodes, nodeCount = children.length; i < nodeCount; i++) {
        var child = children[i];
        if (child.nodeType == 1) {
            newNormalize(child);
            continue;
        }
        if (child.nodeType != 3) { continue; }
        var next = child.nextSibling;
        if (next == null || next.nodeType != 3) { continue; }
        var combined_text = child.nodeValue + next.nodeValue;
        var new_node = node.ownerDocument.createTextNode(combined_text);
        node.insertBefore(new_node, child);
        node.removeChild(child);
        node.removeChild(next);
        i--;
        nodeCount--;
    }
 }

 return this.find("span.highlight").each(function() {
    var thisParent = this.parentNode;
    thisParent.replaceChild(this.firstChild, this);
    newNormalize(thisParent);
 }).end();
};
