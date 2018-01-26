var $ = require('jquery'),
    _ = require('underscore'),
    test = require('tape-catch'),
    logger = require('../appjs/logger.js');

// Setup jquery ajax prefilters to adjust ajax calls for testing purposes
$.ajaxPrefilter(function( options ) {
  options.url = 'http://localhost:3033' + options.url;
  options.headers = options.headers || {};
  options.headers['Authorization'] = 'API-KEY auth=u1H4xLSckbnJSYiM5VE0';
});

logger.level = 'debug';

test.onFinish( function() {
  if ( typeof window !== 'undefined' ) { window.close(); }
} );

module.exports = test;
