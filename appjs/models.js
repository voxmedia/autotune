"use strict";

var Backbone = require('backbone'),
    _ = require('underscore'),
    markdown = require('markdown').markdown;

function getEmptyJSON(url) {
  return Backbone.ajax({
    dataType: 'json',
    type: 'GET',
    url: url
  });
}

exports.Project = Backbone.Model.extend({
  urlRoot: '/projects',

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
    if(this.has('slug') && !this.hasChanged('slug')) {
      return [this.urlRoot, this.get('slug')].join('/');
    } else {
      return [this.urlRoot, this.id].join('/');
    }
  },

  build: function() {
    return getEmptyJSON(this.url() + '/build');
  },

  buildAndPublish: function() {
    return getEmptyJSON(this.url() + '/build_and_publish');
  },

  updateSnapshot: function() {
    return getEmptyJSON(this.url() + '/update_snapshot');
  },

  hasInstructions: function() {
    return this.blueprint && this.blueprint.get('config')['instructions'];
  },

  instructions: function() {
    if(this.hasInstructions()) {
      return markdown.toHTML(this.blueprint.get('config')['instructions']);
    }
  },

  hasStatus: function() {
    var iteratee = function(m, i) {
      return m || this.get( 'status' ) === i;
    };
    return _.reduce( arguments, _.bind(iteratee, this), false );
  },
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

  hasStatus: function() {
    var iteratee = function(m, i) {
      return m || this.get( 'status' ) === i;
    };
    return _.reduce( arguments, _.bind(iteratee, this), false );
  },

  urlRoot: '/blueprints',

  updateRepo: function() {
    return getEmptyJSON(this.url() + '/update_repo');
  }
});

exports.BlueprintCollection = Backbone.Collection.extend({
  model: exports.Blueprint,
  url: '/blueprints'
});
