"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('../models'),
    logger = require('../logger'),
    camelize = require('underscore.string/camelize');

require('pnotify/pnotify.buttons');

module.exports = Backbone.View.extend({
  events: {
    'click a[href]': 'handleLink'
  },

  initialize: function(options) {
    if (_.isObject(options)) {
      _.extend(this, options);
    }

    if(_.isObject(this.collection)) {
      this.listenTo(this.collection, 'all', function(name, inst, data, xhr) { logger.debug(name, arguments); });
      this.listenTo(this.collection, 'reset change sort sync', _.debounce(this.render, 300, true));
      this.listenTo(this.collection, 'error', this.handleSyncError);
    }

    if(_.isObject(this.model)) {
      this.listenTo(this.model, 'all', function(name, inst, data, xhr) { logger.debug(name, arguments); });
      this.listenTo(this.model, 'reset change sync', _.debounce(this.render, 300, true));
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
    this.hook('beforeRender');

    this.$el.html(this.template(this));

    this.app.view.spinStop();

    this.hook('afterRender');

    return this;
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
    logger.debug(tmplObj);
    this.$el.html(tmpl(tmplObj));
    this.app.view.spinStop();
  },

  getObjects: function() {
    if ( _.size(this.query) > 0 ) {
      logger.debug(this.query);
      return this.collection.where(this.query);
    } else {
      return this.collection.models;
    }
  },

  hasRole: function(role) {
    return _.contains(this.app.user.get('meta').roles, role);
  },

  hook: function() {
    var args = Array.prototype.slice.call(arguments),
        name = args.shift();
    logger.debug('hook ' + name);
    this.trigger(name, args);
    if(_.isFunction(this[name])) { return this[name].apply(this, args); }
  }
});

