var $ = require('jquery'),
    Backbone = require('backbone'),
    _ = require('underscore'),
    test = require('tape-catch');

// Store the original version of Backbone.sync
var backboneSync = Backbone.sync;

// Create a new version of Backbone.sync which calls the stored version after a few changes
Backbone.sync = function (method, model, options) {
  /*
   * Change the `url` property of options to begin with the URL from settings
   * This works because the options object gets sent as the jQuery ajax options, which
   * includes the `url` property
   */
  options.url = 'http://localhost:3033' + (_.isFunction(model.url) ? model.url() : model.url);
  options.headers = options.headers || {};
  options.headers['Authorization'] = 'API-KEY auth=u1H4xLSckbnJSYiM5VE0';

  // Call the stored original Backbone.sync method with the new url property
  return backboneSync(method, model, options);
};

test.onFinish( function() {
  if ( typeof window !== 'undefined' ) {
    window.close();
  }
} );

module.exports = test;
