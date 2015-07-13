"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('../models'),
    logger = require('../logger'),
    BaseView = require('./BaseView');

module.exports = BaseView.extend( {
  initialize: function(options) {
    BaseView.prototype.initialize.call(this, options);
  }
}, require('./mixins/actions'), require('./mixins/form') );
