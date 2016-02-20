"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    logger = require('../../logger'),
    Backbone = require('backbone');

module.exports = {
  events: {
    'click a[href]': 'handleLink'
  },

  handleLink: function(eve) {
    var href = $(eve.currentTarget).attr('href'),
        target = $(eve.currentTarget).attr('target');

    // should we handle this link?
    // if it doesn't have a target and you didn't hold down a modifer key
    if ( href && !target && !eve.metaKey && !eve.ctrlKey &&
         !/^(\w+:)?\/\//.test(href) ) {

      if ( /^#[\w-_]+$/.test( href ) ) {
        // handle a current page anchor link
        var $tab = this.$('.nav-tabs a[href='+href+']');
        logger.debug( 'handleLink', href );
        window.location.hash = href;
        if ( $tab && eve.currentTarget !== $tab[0] ) {
          logger.debug( 'show tab and reset scroll' );
          _.defer(function() {
            // Works better when deferred
            $(window).scrollTop(0);
            $tab.tab('show');
          });
        }
      } else {
        // handle a partial url
        eve.preventDefault();
        eve.stopPropagation();
        logger.debug( 'handleLink', href );
        Backbone.history.navigate( href, { trigger: true } );
      }
    }
  }
};
