"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('../models'),
    logger = require('../logger'),
    helpers = require('../helpers');

var BaseView = Backbone.View.extend({
  loaded: true,
  firstRender: true,
  initialize: function(options) {
    if (_.isObject(options)) {
      _.extend(this, _.pick(options, 'app', 'query'));
    }

    this.hook('afterInit', options);
  },

  render: function() {
    var scrollPos = $(window).scrollTop(),
        activeTab = this.$('.nav-tabs .active a').attr('href'),
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
      if ( view.firstRender ) {
        logger.debug( 'first render' );
        view.firstRender = false;
      } else {
        logger.debug('re-render; fix scroll and tabs',
                     scrollPos, activeTab, $(document).height());
        view.$('.nav-tabs a[href='+activeTab+']').tab('show');
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
    return this;
  },

  unload: function() {
    this.loaded = false;
    if ( this.parentView ) { this.parentView = null; }
    return this;
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

/*
 * Improved extend function that takes multiple objects. Also merges all event objects instead
 * of overridding.
 *
 * http://stackoverflow.com/questions/9403675/backbone-view-inherit-and-extend-events-from-parent
 */
BaseView.extend = function() {
  var obj = _.extend.apply(_, arguments);

  obj.events = _.extend(
    _.reduce(
      _.pluck(arguments, 'events'),
      function(m, o) { return _.extend(m, o); },
      {} ),
    this.prototype.events
  );

  return Backbone.View.extend.call(this, obj);
};

module.exports = BaseView;
