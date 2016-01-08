"use strict";

var Backbone = require('backbone'),
    Theme = require('./theme');

var ThemeCollection = Backbone.Collection.extend({
  model: Theme,
  url: '/themes',

  get: function(id_or_slug) {
    return this.find(function(model) {
      return model.id === id_or_slug || model.get('slug') === id_or_slug;
    });
  }
});

module.exports = ThemeCollection;
