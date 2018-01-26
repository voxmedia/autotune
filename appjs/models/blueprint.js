"use strict";

var Backbone = require('backbone'),
    _ = require('underscore'),
    utils = require('../utils'),
    ProjectCollection = require('./project_collection');

var Blueprint = Backbone.Model.extend({
  /**
   * Constructor.
   * @param {object} args Arguments passed to the constructor
   **/
  initialize: function() {
    this.projects = new ProjectCollection([], { blueprint: this });
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

  /**
   * Does this project have any of these types?
   * @param {string} status Check for this status
   * @returns {boolean}
   **/
  hasType: function() {
    var iteratee = function(m, i) {
      return m || this.get( 'type' ) === i;
    };
    return _.reduce( arguments, _.bind(iteratee, this), false );
  },

  hasPreviewType: function() {
    var iteratee = function(m, i) {
      return m || this.get('config')['preview_type'] === i;
    };
    return _.reduce( arguments, _.bind(iteratee, this), false );
  },

  /**
   * Does this project have a form?
   * @returns {boolean}
   **/
  hasForm: function() {
    return this.has('config') && this.get('config').form !== undefined;
  },

  urlRoot: '/blueprints',

  /**
   * Update this blueprint.
   * @returns {object} jqXHR object
   **/
  updateRepo: function() {
    this.set({'status': 'updating'});
    return Backbone.ajax({
      dataType: 'json',
      type: 'GET',
      url: this.url() + '/update_repo'
    });
  },

  /**
   * Get the url for one of the built projects (preview or publish).
   * @param {string} type - Type of the url (preview, publish)
   * @param {string} preferredProto - Protocol to use if possible (http, https)
   * @param {string} path - include this path in the URL
   * @returns {string} url
   **/
  getMediaUrl: function(path) {
    if ( !this.has('media_url') ) { return ''; }

    return utils.buildUrl( this.get('media_url'), path );
  }
});

module.exports = Blueprint;
