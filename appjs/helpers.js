"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    querystring = require('querystring'),
    escape = require('escape-html');

module.exports = {
  render: function(template, templateObj) {
    templateObj = _.extend(templateObj || {}, this, require('underscore.string'));

    return template(templateObj);
  },

  getObjects: function() {
    return this.collection.models;
  },

  hasObjects: function() {
    if (this.collection.models.length > 0) {
      return this.collection.models.length > 0;
    } else {
      return this.collection.models.length > 0;
    }
  },

  hasRole: function(role) {
    return _.contains(this.app.user.get('meta').roles, role);
  },

  /***********
   * Pagination helpers
   */

  hasNextPage: function() {
    return this.collection.hasNextPage();
  },

  hasPreviousPage: function() {
    return this.collection.hasPreviousPage();
  },

  getPageUrl: function(page) {
    var base = _.result(this.collection, 'url'),
        qs = _.extend({page: page}, this.query);
    return base + '?' + querystring.stringify( qs );
  },

  getNextPageUrl: function() {
    return this.getPageUrl( this.collection.state.currentPage + 1 );
  },

  getPreviousPageUrl: function() {
    return this.getPageUrl( this.collection.state.currentPage - 1 );
  },

  /**********
   * Expose other stuff as helpers
   */
  escape: escape
};
