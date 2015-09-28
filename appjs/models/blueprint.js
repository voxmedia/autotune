"use strict";

var Backbone = require('backbone'),
    _ = require('underscore'),
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
  }
});

module.exports = Blueprint;
