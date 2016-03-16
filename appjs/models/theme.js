"use strict";

var Backbone = require('backbone'),
    _ = require('underscore');

var Theme = Backbone.Model.extend({
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
   * Is this the default blueprint for the group?
   * @returns {boolean}
   **/
  isDefault: function() {
    return !this.has('parent_id') || this.get('parent_id') === undefined;
  },

  /**
   * Does this theme have any of these statuses?
   * @param {string} status Check for this status
   * @returns {boolean}
   **/
  hasStatus: function() {
    var iteratee = function(m, i) {
      return m || this.get( 'status' ) === i;
    };
    return _.reduce( arguments, _.bind(iteratee, this), false );
  },

  themeData: function(subGroup) {
    if( !this.get('data') || !this.get('data')[subGroup]) {
      return {};
    }
    return this.get('data')[subGroup];
  },

  urlRoot: '/themes',

  /**
   * Reset this theme.
   * @returns {object} jqXHR object
   **/
  reset: function() {
    this.set({'status': 'updating'});
    return Backbone.ajax({
      dataType: 'json',
      type: 'GET',
      url: this.url() + '/reset'
    });
  }
});

module.exports = Theme;
