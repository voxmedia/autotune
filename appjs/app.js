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

// Make libraries accessible to global scope, for console use and error logging
window.Backbone = Backbone;
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
      if(this.sseClosingTimeout){
        this.debug('Clearing sse closing timeout');
        clearTimeout(this.sseClosingTimeout);
      }
    }, this));

    $(window).on('blur', _.bind(function(){
      this.has_focus = false;
      this.sseClosingTimeout = setTimeout(_.bind(this.stopListeningForChanges, this), 10000);
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
      this.view.warning("Stopped automatic status update due to inactivity. Refresh page to see recent changes.");
      return;
    }

    this.debug('Init server event listener');
    this.msgListener = new window.EventSource('/changemessages');

    this.msgListener.addEventListener('change', _.bind(function(evt) {
      var msg = JSON.parse(evt.data);
      var refresh = false;

      // Don't proceed if the change is on a different type of data
      if(!this.dataToRefresh || (msg.type !== this.dataType)){
        return;
      }

      // check if the changed object id is in the activedata
      if(this.dataToRefresh instanceof Backbone.Collection){
        refresh = _.where(this.dataToRefresh.models, {id: msg.id}).length !== 0;
      }
      else {
        refresh = this.dataToRefresh.get("id") === msg.id;
      }

      if(refresh){
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
      if(this.sseRetryCount <= 10){
        this.sseRetryTimeout = setTimeout(_.bind(this.startListeningForChanges,this), 2000);
      }
      if(this.sseRetryCount > 2){
        this.view.warning("Could not get automatic status updates. Retrying...");
      }
      if(this.sseRetryCount >=10){
        this.view.error("Could not get automatic status updates. Refresh page to see recent changes.");
      }
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
      this.view.warning("Stopped automatic status update due to inactivity. Refresh page to see recent changes.");
    }
  },

  setActiveData: function(type, data, query){    
    this.dataType = type;
    this.dataToRefresh = data;
    this.dataQuery = query;
  }
});
