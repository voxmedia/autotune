"use strict";

var Backbone = require('backbone'),
    Blueprint = require('./blueprint');

var BlueprintCollection = Backbone.Collection.extend({
  model: Blueprint,
  url: '/blueprints',

  get: function(id_or_slug) {
    return this.find(function(model) {
      return model.id === id_or_slug || model.get('slug') === id_or_slug;
    });
  }
});

module.exports = BlueprintCollection;
