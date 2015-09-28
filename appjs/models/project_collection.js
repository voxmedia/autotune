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
    pageSize: 15
  },

  parseState: function (response, queryParams, state, options) {
    return {totalRecords: parseInt(options.xhr.getResponseHeader("X-Total"))};
  }
});

module.exports = ProjectCollection;
