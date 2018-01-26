"use strict";

var $ = require('jquery');

module.exports = {
  /**
   * Build a url for deployed files
   * @param {string} base - Type of the url (preview, publish)
   * @param {string} path - include this path in the URL
   * @param {string} proto - Protocol to use if possible (http, https)
   * @returns {string} url
   **/
  buildUrl: function(base, path, proto) {
    if ( !base ) { return ''; }

    // check if our base url ends in a slash
    var trailingSlash = base.substr(-1) === '/',
        ret = base;

    // if a protocol (http or https) is not supplied, figure it out
    if ( !proto ) {
      proto = window.location.protocol.replace( ':', '' );
    }

    // Build a url which includes a protocol
    if ( base.match(/^\/\//) && proto !== '' ) {
      base = proto + ':' + base;
    }

    // combine base and path, making sure we have one slash between them
    if ( path && base.substr(-1) === '/' ) {
      if ( path[0] === '/' ) {
        ret = base + path.substr(1);
      } else {
        ret = base + path;
      }
    } else if ( path ) {
      if ( path[0] === '/' ) {
        ret = base + path;
      } else {
        ret = base + '/' + path;
      }
    }

    // add a trailing slash if the path wasn't for a file and our original
    // base url had a trailing slash
    if ( trailingSlash && !ret.match(/\..{1,6}$/) && ret.substr(-1) !== '/' ) {
      ret = ret + '/';
    }

    return ret;
  },
  fixSelectizeInputSizing: function(targetSelector, targetDropdown) {
    var childWidth = 0;
    $.each(targetDropdown.children(), function(k,v){
      if ($(this).innerWidth() > childWidth) {
        childWidth = $(this).innerWidth();
      }
    });
    targetSelector.innerWidth(childWidth);
    targetSelector.children('input').innerWidth(childWidth);
  }
};
