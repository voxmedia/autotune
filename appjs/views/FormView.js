"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('../models'),
    logger = require('../logger'),
    camelize = require('underscore.string/camelize'),
    BaseView = require('./BaseView');

module.exports = BaseView.extend({
  events: {
    'click a[href]': 'handleLink',
    'submit form': 'handleForm',
    'click button[data-action],a[data-action]': 'handleAction',
    'change select[data-auto-submit=true]': 'submitForm',
    'change :input': 'handleFormChange'
  },

  initialize: function(options) {
    BaseView.prototype.initialize.call(this, options);
  },

  _modelOrCollection: function() {
    if(_.isObject(this.collection)) { return this.collection; }
    else if(_.isObject(this.model)) { return this.model; }
  }
});

