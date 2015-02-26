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

Backbone.$ = $;

var bootstrap = require('bootstrap');

// Load our components and run the app
var Router = require('./router');

var router = new Router();

$(document).ready(function() {
  Backbone.history.start({pushState: true});
});
