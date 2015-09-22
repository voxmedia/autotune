"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone');

module.exports = {
  events: {
    'click a[href]': 'handleLink'
  },

  handleLink: function(eve) {
    var href = $(eve.currentTarget).attr('href'),
        target = $(eve.currentTarget).attr('target');
    if (href && !target && !/^(https?:\/\/|#)/.test(href) && !eve.metaKey && !eve.ctrlKey) {
      // only handle this link if it's a fragment and you didn't hold down a modifer key
      eve.preventDefault();
      eve.stopPropagation();
      Backbone.history.navigate(
        $(eve.currentTarget).attr('href'), { trigger: true });
    }
  }
};
