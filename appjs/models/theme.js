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

  urlRoot: '/themes'
});

module.exports = Theme;
