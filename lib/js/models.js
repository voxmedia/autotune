"use strict";

var Backbone = require('backbone'),
    _ = require('underscore');

exports.Build = Backbone.Model.extend({
  initialize: function(args) {
    if(_.isObject(args.blueprint)) {
      this.blueprint = args.blueprint;
    } else if(!_.isUndefined(args.blueprint_name)) {
      this.blueprint = new exports.Blueprint({name: args.blueprint_name});
    }
    this.urlRoot = this.blueprint.url() + '/builds/';
  }
});
exports.BuildCollection = Backbone.Collection.extend({
  initialize: function(models, opts) {
    this.blueprint = opts.blueprint;
    this.url = this.blueprint.url() + '/builds/';
  },
  model: exports.Build,
  url: function() { return this.blueprint.url() + '/builds/'; }
});
exports.Blueprint = Backbone.Model.extend({
  initialize: function() {
    this.builds = new exports.BuildCollection([], { blueprint: this });
  },
  urlRoot: '/blueprints/'
});
exports.BlueprintCollection = Backbone.Collection.extend({
  url: '/blueprints/',
  model: exports.Blueprint
});
