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

  Backbone.history.start({pushState: true});
};

_.extend(window.App.prototype, {
  isDev: function() {
    return this.config.env === 'development';
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
  }
});
