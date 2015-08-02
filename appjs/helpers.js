"use strict";

var $ = require('jquery'),
    _ = require('underscore');

module.exports = {
  render: function(template, templateObj) {
    templateObj = _.extend(templateObj || {}, this, require('underscore.string'));

    return template(templateObj);
  },

  getObjects: function() {
    if ( _.size(this.query) > 0 ) {
      return this.collection.where(this.query);
    } else {
      return this.collection.models;
    }
  },

  hasObjects: function() {
    if ( _.size(this.query) > 0 ) {
      return this.collection.where(this.query).length > 0;
    } else {
      return this.collection.models.length > 0;
    }
  },

  hasRole: function(role) {
    return _.contains(this.app.user.get('meta').roles, role);
  }
};
