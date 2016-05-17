"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    tinycolor = require('tinycolor2'),
    querystring = require('querystring'),
    escape = require('escape-html'),
    _string = require('underscore.string');

module.exports = {
  render: function(template, templateObj) {
    templateObj = _.extend(templateObj || {}, this, _string);

    return template(templateObj);
  },

  getObjects: function() {
    return this.collection.models;
  },

  hasObjects: function() {
    if (this.collection) {
      return this.collection.models.length > 0;
    } else {
      return false;
    }
  },

  hasRole: function(role) {
    return this.app.hasRole(role);
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
   * Theme editor helpers
   */
   isColor: function(color){
     return tinycolor(color).isValid();
   },

  /**********
   * Expose other stuff as helpers
   */
  escape: escape
};
