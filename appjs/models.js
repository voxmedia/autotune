"use strict";

var Backbone = require('backbone'),
    _ = require('underscore');

exports.Project = Backbone.Model.extend({
  initialize: function(args) {
    if(_.isObject(args.blueprint)) {
      this.blueprint = args.blueprint;
    } else if(!_.isUndefined(args.blueprint_name)) {
      this.blueprint = new exports.Blueprint({name: args.blueprint_name});
    }
  },
  url: function() {
    if(this.attributes.slug) {
      return this.urlRoot + this.attributes.slug;
    } else {
      return this.urlRoot + this.id;
    }
  },
  urlRoot: '/projects/'
});
exports.ProjectCollection = Backbone.Collection.extend({
  model: exports.Project,
  url: '/projects/'
});
exports.Blueprint = Backbone.Model.extend({
  initialize: function() {
    this.projects = new exports.ProjectCollection([], { blueprint: this });
  },
  url: function() {
    if(this.attributes.slug) {
      return this.urlRoot + this.attributes.slug;
    } else {
      return this.urlRoot + this.id;
    }
  },
  thumbUrl: function() {
    return this.url() + '/thumb';
  },
  urlRoot: '/blueprints/'
});
exports.BlueprintCollection = Backbone.Collection.extend({
  url: '/blueprints/',
  model: exports.Blueprint
});
