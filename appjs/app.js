/*
 * autotune
 * https://github.com/voxmedia/autotune
 *
 * Copyright (c) 2015 Ryan Mark
 * Licensed under the BSD license.
 */

// Load jQuery and Backbone, make sure Backbone uses jQuery
var $ = require('jquery'),
    Backbone = require('backbone');

window.$ = Backbone.$ = $;

var bootstrap = require('bootstrap'),
    Alpaca = require('./vendor/alpaca');

// Load our components and run the app
var Router = require('./router');

window.App = function(config) {
  this.config = config;
  this.router = new Router({app: this});

  Backbone.history.start({pushState: true});
};
