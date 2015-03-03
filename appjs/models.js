"use strict";

var Backbone = require('backbone'),
    _ = require('underscore');

exports.Project = Backbone.Model.extend({
  initialize: function(args) {
    if(_.isObject(args)) {
      if(_.isObject(args.blueprint)) {
        this.blueprint = args.blueprint;
        // attributes are already set at this point, so we have to delete the blueprint object
        delete this.attributes.blueprint;
      } else if(!_.isUndefined(args.blueprint_name)) {
        this.blueprint = new exports.Blueprint({name: args.blueprint_name});
      }
    }
  },
  url: function() {
    if(this.isNew()) { return this.urlRoot; }
    if(this.has('slug')) {
      return [this.urlRoot, this.get('slug')].join('/');
    } else {
      return [this.urlRoot, this.id].join('/');
    }
  },
  urlRoot: '/projects'
});

exports.ProjectCollection = Backbone.Collection.extend({
  model: exports.Project,
  url: '/projects'
});

exports.Blueprint = Backbone.Model.extend({
  initialize: function() {
    this.projects = new exports.ProjectCollection([], { blueprint: this });
  },
  url: function() {
    if(this.isNew()) { return this.urlRoot; }
    if(this.attributes.slug) {
      return [this.urlRoot, this.attributes.slug].join('/');
    } else {
      return [this.urlRoot, this.id].join('/');
    }
  },
  thumbUrl: function() {
    return [this.url(), 'thumb'].join('/');
  },
  urlRoot: '/blueprints'
});

exports.BlueprintCollection = Backbone.Collection.extend({
  model: exports.Blueprint,
  url: '/blueprints'
});
