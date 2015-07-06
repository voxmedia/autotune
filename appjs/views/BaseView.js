"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('../models'),
    logger = require('../logger'),
    helpers = require('../helpers');

module.exports = Backbone.View.extend({
  events: {
    'click a[href]': 'handleLink'
  },

  initialize: function(options) {
    this.loaded = this.firstRender = true;

    if (_.isObject(options)) {
      _.extend(this, options);
    }

    if(_.isObject(this.collection)) {
      this.listenTo(this.collection, 'all', function(name, inst, data, xhr) { logger.debug(name, arguments); });
      this.listenTo(this.collection, 'reset change sort sync', _.debounce(this.render, 300));
      this.listenTo(this.collection, 'error', this.handleSyncError);
    }

    if(_.isObject(this.model)) {
      this.listenTo(this.model, 'all', function(name, inst, data, xhr) { logger.debug(name, arguments); });
      this.listenTo(this.model, 'reset change sync', _.debounce(this.render, 300));
      this.listenTo(this.model, 'error', this.handleSyncError);
    }

    this.hook('afterInit', options);
  },

  handleLink: function(eve) {
    var href = $(eve.currentTarget).attr('href'),
        target = $(eve.currentTarget).attr('target');
    if (href && !target && !/^(https?:\/\/|#)/.test(href) && !eve.metaKey && !eve.ctrlKey) {
      // only handle this link if it's a fragment and you didn't hold down a modifer key
      eve.preventDefault();
      eve.stopPropagation();
      Backbone.history.navigate(
        $(eve.currentTarget).attr('href'),
        {trigger: true});
    }
  },

  render: function() {
    var scrollPos = $(window).scrollTop(),
        activeTab = this.$('.nav-tabs .active a').attr('href'),
        view = this;

    if ( this.loaded ) {
      return this.hook('beforeRender').then(function() {
        view.$el.html( helpers.render( view.template, view.getTemplateObj() ) );

        return view.hook( 'afterRender' );
      }).then(function() {
        if ( view.firstRender ) {
          logger.debug( 'first render' );
          view.firstRender = false;
        } else {
          logger.debug('re-render; fix scroll and tabs', scrollPos, activeTab, $(document).height());
          view.$('.nav-tabs a[href='+activeTab+']').tab('show');
          $(window).scrollTop(scrollPos);
        }

        view.app.trigger( 'loadingStop' );
      });
    } else {
      return Promise.resolve();
    }
  },

  getTemplateObj: function() {
    return {
      model: this.model,
      collection: this.collection,
      app: this.app,
      query: this.query
    };
  },

  handleSyncError: function(model_or_collection, resp, options) {
    var tmpl,
        tmplObj = {
          app: this.app, resp: resp, options: options,
          model_or_collection: model_or_collection };
    if (resp.status === 404) {
      tmpl = require('../templates/not_found.ejs');
    } else if (resp.status === 403) {
      tmpl = require('../templates/not_allowed.ejs');
    } else {
      tmpl = require('../templates/error.ejs');
    }
    this.$el.html(helpers.render(tmpl, tmplObj));
    this.app.trigger('loadingStop');
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

  extend: function(child) {
    var view = Backbone.View.extend.apply(this, arguments);
    view.prototype.events = _.extend({}, this.prototype.events, child.events);
    return view;
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

