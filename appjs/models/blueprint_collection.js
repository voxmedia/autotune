"use strict";

var Backbone = require('backbone'),
    Blueprint = require('./blueprint');

var BlueprintCollection = Backbone.Collection.extend({
  model: Blueprint,
  url: '/blueprints'
});

module.exports = BlueprintCollection;
