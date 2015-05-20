/*
 * autotune
 * https://github.com/voxmedia/autotune
 *
 * Copyright (c) 2015 Ryan Mark
 * Licensed under the BSD license.
 */

// Load jQuery and Backbone, make sure Backbone uses jQuery
var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone');

window.$ = Backbone.$ = $;
window._ = _;

var bootstrap = require('bootstrap'),
    Alpaca = require('./vendor/alpaca');

// Load our components and run the app
var Router = require('./router');

window.App = function(config) {
  this.config = config;
  this.router = new Router({app: this});
  this.msgListener = null;
  this.has_focus = true;

  Backbone.history.start({pushState: true});

  if ( window.EventSource ) {
    $(window).on('focus', _.bind(function(){
      this.has_focus = true;
      if(!this.sseRetryCount || this.sseRetryCount === 0){
        this.startListeningForChanges();
      }
    }, this));

    $(window).on('blur', _.bind(function(){
      this.has_focus = false;
      setTimeout(_.bind(this.stopListeningForChanges, this), 10000);
    }, this));

    this.startListeningForChanges();
  }
};

_.extend(window.App.prototype, {
  isDev: function() {
    return this.config.env === 'development' || this.config.env === 'staging';
  },

  log: function() {
    console.log.apply(console, arguments);
  },

  debug: function() {
    if (this.isDev()) { console.debug.apply(console, arguments); }
  },

  error: function() {
    console.error.apply(console, arguments);
  },

  analyticsEvent: function() {
    if ( window.ga ) {
      var ga = window.ga;
      if ( arguments[0] === 'pageview' ) {
        ga('send', 'pageview');
      }
    }
  },

  startListeningForChanges: function(){
    if(this.msgListener && (this.msgListener.readyState === this.msgListener.OPEN || this.msgListener.readyState === this.msgListener.CONNECTING)){
      return;
    }
    if(!this.has_focus){
      return;
    }
    this.debug('Init server event listener');
    this.msgListener = new window.EventSource('/changemessages');

    this.msgListener.addEventListener('change', _.bind(function() {
     if(this.dataToRefresh){
        this.debug('server event; updating data');
        if ( this.dataQuery ) {
          this.dataToRefresh.fetch({data: this.dataQuery});
        } else {
          this.dataToRefresh.fetch();
        }
      }
    }, this));

    this.msgListener.onerror = _.bind(function(){
      if(!this.sseRetryCount){
        this.sseRetryCount = 0;
      }
      this.sseRetryCount++;
      this.debug('Could not connect to event stream "changemessages"');
      if(this.msgListener){
        this.msgListener.close();
      }
      setTimeout(_.bind(this.startListeningForChanges,this), this.sseRetryCount * 1000);
    },this);

    this.msgListener.onopen = function(){
      this.sseRetryCount = 0;
    };
  },

  stopListeningForChanges: function(ignoreFocus){
    this.debug('Checking for focus');
    if(ignoreFocus || this.has_focus){
      return;
    }
    if(this.msgListener && this.msgListener.readyState === this.msgListener.OPEN){
      this.debug('Close event listener');
      this.msgListener.close();
    }
  },

  setActiveData: function(data, query){
    this.dataToRefresh = data;
    this.dataQuery = query;
  }
});
