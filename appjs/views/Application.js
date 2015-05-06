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
    this.$('#spinner').fadeOut('fast');
  },

  setTab: function(name) {
    this.$('#nav [data-tab]').removeClass('active');
    if(name) { this.$('#nav [data-tab='+name+']').addClass('active'); }
  },

  clearError: function() {
    this.$('#flash').empty();
  }
});
