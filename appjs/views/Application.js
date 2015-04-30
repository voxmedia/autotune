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
    $('#main').empty().append(view.$el);
  },

  spinStart: function() {
    $('#spinner').show();
  },

  spinStop: function() {
    $('#spinner').fadeOut('fast');
  },

  setTab: function(name) {
    $('#nav [data-tab]').removeClass('active');
    if(name) { $('#nav [data-tab='+name+']').addClass('active'); }
  },

  clearError: function() {
    $('#notice').empty();
  }
});
