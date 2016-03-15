"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    camelize = require('underscore.string/camelize'),
    models = require('../models'),
    logger = require('../logger'),
    helpers = require('../helpers');

var BaseView = Backbone.View.extend({
  loaded: true,
  firstRender: true,
  events: {
    'click button[data-hook], a[data-hook]': 'handleHook'
  },

  initialize: function(options) {
    if (_.isObject(options)) {
      _.extend(this, _.pick(options, 'app', 'query'));
    }

    this.hook('afterInit', options);
  },

  handleHook: function(eve) {
    var $btn = $(eve.currentTarget);

    if ( $btn.hasClass('btn') ) { $btn.button( 'loading' ); }

    this.hook(
      camelize($btn.data('hook')), $btn.data('hook-options')
    ).catch(function(err) {
      logger.error('Hook failed', err);
    }).then(function() {
      if ( $btn.hasClass('btn') ) { $btn.button( 'reset' ); }
    });
  },

  render: function() {
    var scrollPos = $(window).scrollTop(),
        activeTab = window.location.hash,
        view = this;

    // Only render if this view is loaded
    if ( !this.loaded ) { return Promise.resolve(); }

    // Do some renderin'. First up: beforeRender()
    return view.hook( 'beforeRender' ).then(function() {
      // Generate the element using template and templateData()
      view.$el.html(
        helpers.render(
          view.template, view.templateData() ) );

      return view.hook( 'afterRender' );
    }).then(function() {
      // Set a tab on the page if we have an anchor
      if ( activeTab ) {
        logger.debug( 'set tab', activeTab );
        view.$('.nav-tabs a[href='+activeTab+']').tab('show');
      }

      if ( view.firstRender ) {
        // Reset first render flag
        logger.debug( 'first render' );
        view.firstRender = false;
      } else {
        // Reset scroll position
        logger.debug('re-render; set scroll',
                     activeTab, scrollPos, $(document).height());
        $(window).scrollTop(scrollPos);
      }

      view.app.trigger( 'loadingStop' );
    });
  },

  templateData: function() {
    return {
      model: this.model,
      collection: this.collection,
      app: this.app,
      query: this.query
    };
  },

  load: function(parentView) {
    this.loaded = this.firstRender = true;
    this.parentView = parentView;
    return this.trigger('load');
  },

  unload: function() {
    this.loaded = false;
    if ( this.parentView ) { this.parentView = null; }
    return this.trigger('unload');
  },

  hook: function() {
    var args = Array.prototype.slice.call(arguments),
        name = args.shift();

    logger.debug('hook ' + name);

    this.trigger(name, args);

    if( _.isFunction(this[name]) ) {
      return Promise.resolve( this[name].apply(this, args) );
    } else {
      return Promise.resolve( this );
    }
  }
});

/* Take an array of mixins and objects and return a new Backbone view class.
 * Merges objects in the event attributes instead of overridding.
 *
 * http://stackoverflow.com/questions/9403675/backbone-view-inherit-and-extend-events-from-parent
 */
BaseView.extend = function() {
  // make a new array, starting with an empty object and add all the arguments
  var args = [ { } ].concat( Array.prototype.slice.call(arguments) );
  // < [{}, arg1, arg2, arg3...]
  // merge all the objects together...
  var obj = _.extend.apply(_, args);

  // Go through all the arguments and merge together their event attributes
  obj.events = _.extend(
    _.reduce(
      _.pluck(arguments, 'events'),
      function(m, o) { return _.extend(m, o); },
      {} ),
    this.prototype.events
  );

  // Make a view
  return Backbone.View.extend.call(this, obj);
};

module.exports = BaseView;
