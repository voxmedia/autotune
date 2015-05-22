"use strict";

var Backbone = require('backbone'),
    _ = require('underscore'),
    moment = require('moment'),
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

  buildData: function() {
    return _.extend({
      'base_url': (this.isDraft() || this.hasUnpublishedUpdates()) ? this.get('preview_url') : this.get('publish_url')
    }, this.formData());
  },

  formData: function() {
    return _.extend({
      'title': this.get('title'),
      'slug': this.get('slug'),
      'theme': this.get('theme')
    }, this.get('data'));
  },

  hasStatus: function() {
    var iteratee = function(m, i) {
      return m || this.get( 'status' ) === i;
    };
    return _.reduce( arguments, _.bind(iteratee, this), false );
  },

  isDraft: function() {
    return ! this.isPublished();
  },

  isPublished: function() {
    return !!this.get('published_at');
  },

  hasUnpublishedUpdates: function() {
    return moment(this.get('data_updated_at')).isAfter(this.get('published_at'));
  },

  publishedTime: function(){
    if(this.isPublished){
      var localTime = moment.utc(this.get('published_at')).toDate();
      return moment(localTime).format('MMM DD, YYYY - hh:mmA');
    }
  },

  /**
   * Get the url to the preview
   * @param {string} preferredProto - Return the url with this protocol (http, https) if possible
   * @returns {string} url
   **/
  getPreviewUrl: function(preferredProto) {
    return this.getBuildUrl('preview', preferredProto);
  },

  /**
   * Get the url to the published project
   * @param {string} preferredProto - Return the url with this protocol (http, https) if possible
   * @returns {string} url
   **/
  getPublishUrl: function(preferredProto) {
    return this.getBuildUrl('publish', preferredProto);
  },

  /**
   * Get the url for one of the built projects (preview or publish)
   * @param {string} type - Type of the url (preview, publish)
   * @param {string} preferredProto - Protocol to use if possible (http, https)
   * @returns {string} url
   **/
  getBuildUrl: function(type, preferredProto) {
    var key = ( type === 'publish' ) ? 'publish_url' : 'preview_url';
    if ( !this.has(key) ) { return ''; }
    var base = this.get(key);
    if ( base.match(/^http/) ) {
      return base;
    } else if ( base.match(/^\/\//) ) {
      return preferredProto + base;
    } else {
      return base;
    }
  }
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
