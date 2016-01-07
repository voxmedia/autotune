"use strict";

var Backbone = require('backbone'),
    _ = require('underscore');

var Theme = Backbone.Model.extend({
  /**
   * Constructor.
   * @param {object} args Arguments passed to the constructor
   **/
  initialize: function() {
    this.projects = null;
  },

  /**
   * Get the AJAX endpoint for this blueprint.
   * @returns {string}
   **/
  url: function() {
    if(this.isNew()) { return this.urlRoot; }
    if(this.attributes.value) {
      return [this.urlRoot, this.attributes.value].join('/');
    } else {
      return [this.urlRoot, this.id].join('/');
    }
  },

  urlRoot: '/themes'
});

module.exports = Theme;
