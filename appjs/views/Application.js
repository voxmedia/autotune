"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('../models'),
    BaseView = require('./BaseView');

module.exports = BaseView.extend({
  className: 'container-fluid',
  template: require('../templates/application.ejs'),

  display: function(view) {
    this.$('#main').empty().append(view.$el);
  },

  spinStart: function() {
    this.$('#spinner').show();
  },

  spinStop: function() {
    _.defer(_.bind(function() {
      this.$('#spinner').fadeOut('fast');
    }, this));
  },

  setTab: function(name) {
    this.$('#nav [data-tab]').removeClass('active');
    if(name) { this.$('#nav [data-tab='+name+']').addClass('active'); }
  },

  clearError: function() {
    this.$('#flash').empty();
  }
});
