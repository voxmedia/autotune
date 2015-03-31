"use strict";

var Backbone = require('backbone'),
    _ = require('underscore'),
    markdown = require('markdown').markdown;

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
  hasInstructions: function() {
    return this.blueprint && this.blueprint.get('config')['instructions'];
  },
  instructions: function() {
    if(this.hasInstructions()) {
      return markdown.toHTML(this.blueprint.get('config')['instructions']);
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
  placeholderThumbUrl: function() {
    if(this.attributes.config.thumbnail){
      console.log(this);
      // Using github link for now until we grab and host the thumbnail images
      return [(this.attributes.repo_url).replace('.git', '').replace('github', 'raw.githubusercontent'), 'master', this.attributes.config.thumbnail].join('/');
    } else {
      return '/assets/autotune/at_placeholder.png';
    }
  },
  urlRoot: '/blueprints'
});

exports.BlueprintCollection = Backbone.Collection.extend({
  model: exports.Blueprint,
  url: '/blueprints'
});
