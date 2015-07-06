"use strict";

var Backbone = require('backbone'),
    _ = require('underscore'),
    moment = require('moment'),
    markdown = require('markdown').markdown,
    PageableCollection = require('backbone.paginator');

/**
 * Wrapper around Backbone.ajax where a simple `Accepted` status response with an empty
 * body is expected.
 * @param {string} url URL to retrieve via GET HTTP request
 **/
function getEmptyJSON(url) {
  return Backbone.ajax({
    dataType: 'json',
    type: 'GET',
    url: url
  });
}

exports.Project = Backbone.Model.extend({
  urlRoot: '/projects',

  /**
   * Constructor. Looks for `blueprint` or `blueprint_name` in the object passed in.
   * @param {object} args Arguments passed to the constructor
   **/
  initialize: function(args) {
    if(_.isObject(args)) {
      if(_.isObject(args.blueprint)) {
        this.blueprint = args.blueprint;
        // attributes are already set at this point, so we have to delete the blueprint object
        delete this.attributes.blueprint;
      } else if(!_.isUndefined(args.blueprint_name)) {
        this.blueprint = new exports.Blueprint({name: args.blueprint_name});
      }

      if(_.isObject(args.theme)) {
        this.theme = args.theme;
        delete this.attributes.theme;
      }
    }
  },

  /**
   * Get the AJAX endpoint for this project.
   * @returns {string}
   **/
  url: function() {
    if(this.isNew()) { return this.urlRoot; }
    if(this.has('slug') && !this.hasChanged('slug')) {
      return [this.urlRoot, this.get('slug')].join('/');
    } else {
      return [this.urlRoot, this.id].join('/');
    }
  },

  /**
   * Rebuild this project.
   * @returns {object} jqXHR object
   **/
  build: function() {
    return getEmptyJSON(this.url() + '/build');
  },

  /**
   * Rebuild and publish this project.
   * @returns {object} jqXHR object
   **/
  buildAndPublish: function() {
    return getEmptyJSON(this.url() + '/build_and_publish');
  },

  /**
   * Update this project.
   * @returns {object} jqXHR object
   **/
  updateSnapshot: function() {
    return getEmptyJSON(this.url() + '/update_snapshot');
  },

  /**
   * Does the blueprint for this project have instructions?
   * @returns {boolean}
   **/
  hasInstructions: function() {
    if ( this.get('blueprint_config') && this.get('blueprint_config').instructions ) {
      return true;
    } else if ( this.blueprint && this.blueprint.get('config') &&
                this.blueprint.get('config').instructions ) {
      return true;
    }
    return false;
  },

  /**
   * Get the blueprint instructions in HTML format.
   * @returns {string} HTML-formatted instructions
   **/
  instructions: function() {
    if(this.hasInstructions()) {
      var instructions;
      if ( this.get('blueprint_config') ) {
        instructions = this.get('blueprint_config').instructions;
      } else {
        instructions = this.blueprint.get('config')['instructions'];
      }
      return markdown.toHTML(instructions);
    }
  },

  /**
   * Get the data that was passed to the blueprint build.
   * @returns {object} Blueprint build data
   **/
  buildData: function() {
    return _.extend({ 'base_url': this.baseUrl() }, this.formData());
  },

  /**
   * Get the preview or published URL of this project, whichever is more relevent.
   * @returns {string} Preview or publish url
   **/
  baseUrl: function() {
    if (this.isDraft() || this.hasUnpublishedUpdates()) {
      return this.get('preview_url');
    } else {
      return this.get('publish_url');
    }
  },

  /**
   * Get the data to populate the alpaca form.
   * @returns {object} Data for Alpaca
   **/
  formData: function() {
    return _.extend({
      'title': this.get('title'),
      'slug': this.get('slug'),
      'theme': this.get('theme')
    }, this.get('data'));
  },

  /**
   * Does this project have any of these statuses?
   * @param {string} status Check for this status
   * @returns {boolean}
   **/
  hasStatus: function() {
    var iteratee = function(m, i) {
      return m || this.get( 'status' ) === i;
    };
    return _.reduce( arguments, _.bind(iteratee, this), false );
  },

  /**
   * Is this project a draft?
   * @returns {boolean}
   **/
  isDraft: function() {
    return ! this.isPublished();
  },

  /**
   * Has this project been published?
   * @returns {boolean}
   **/
  isPublished: function() {
    return !!this.get('published_at');
  },

  /**
   * Does this project have changes that have not been published?
   * @returns {boolean}
   **/
  hasUnpublishedUpdates: function() {
    return moment(this.get('data_updated_at')).isAfter(this.get('published_at'));
  },

  /**
   * Format and return the publish time in the local timezone.
   * @returns {string} published time
   **/
  publishedTime: function(){
    if(this.isPublished()){
      var localTime = moment.utc(this.get('published_at')).toDate();
      return moment(localTime).format('MMM DD, YYYY - hh:mmA');
    }
  },

  /**
   * Get the url of the preview.
   * @param {string} preferredProto - Return the url with this protocol (http, https) if possible
   * @returns {string} url
   **/
  getPreviewUrl: function(preferredProto) {
    return this.getBuildUrl('preview', preferredProto);
  },

  /**
   * Get the url to the published project.
   * @param {string} preferredProto - Return the url with this protocol (http, https) if possible
   * @returns {string} url
   **/
  getPublishUrl: function(preferredProto) {
    return this.getBuildUrl('publish', preferredProto);
  },

  /**
   * Get the url for one of the built projects (preview or publish).
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
      return preferredProto + ':' + base;
    } else {
      return base;
    }
  }
});

exports.ProjectCollection = PageableCollection.extend({
  model: exports.Project,
  url: '/projects'
});

exports.Blueprint = Backbone.Model.extend({
  /**
   * Constructor.
   * @param {object} args Arguments passed to the constructor
   **/
  initialize: function() {
    this.projects = new exports.ProjectCollection([], { blueprint: this });
  },

  /**
   * Get the AJAX endpoint for this blueprint.
   * @returns {string}
   **/
  url: function() {
    if(this.isNew()) { return this.urlRoot; }
    if(this.attributes.slug) {
      return [this.urlRoot, this.attributes.slug].join('/');
    } else {
      return [this.urlRoot, this.id].join('/');
    }
  },

  /**
   * Does this blueprint have any of these statuses?
   * @param {string} status Check for this status
   * @returns {boolean}
   **/
  hasStatus: function() {
    var iteratee = function(m, i) {
      return m || this.get( 'status' ) === i;
    };
    return _.reduce( arguments, _.bind(iteratee, this), false );
  },

  urlRoot: '/blueprints',

  /**
   * Update this blueprint.
   * @returns {object} jqXHR object
   **/
  updateRepo: function() {
    return getEmptyJSON(this.url() + '/update_repo');
  }
});

exports.BlueprintCollection = Backbone.Collection.extend({
  model: exports.Blueprint,
  url: '/blueprints'
});
