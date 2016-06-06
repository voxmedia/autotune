"use strict";

var Project = require('./project'),
    PageableCollection = require('backbone.paginator');

var ProjectCollection = PageableCollection.extend({
  model: Project,
  url: '/projects',

  state: {
    totalRecords: null,
    totalPages: null,
    firstPage: 1,
    currentPage: 1,
    pageSize: 15,
  },

  parseState: function (response, queryParams, state, options) {
    return {totalRecords: parseInt(options.xhr.getResponseHeader("X-Total"))};
  },

  get: function(id_or_slug) {
    return this.find(function(model) {
      return model.id === id_or_slug || model.get('slug') === id_or_slug;
    });
  }
});

module.exports = ProjectCollection;
