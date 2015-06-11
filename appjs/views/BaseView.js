"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('../models'),
    logger = require('../logger'),
    camelize = require('underscore.string/camelize'),
    alert_template = require('../templates/alert.ejs');

module.exports = Backbone.View.extend({
  events: {
    'click a[href]': 'handleLink'
  },

  initialize: function(options) {
    if (_.isObject(options)) {
      _.extend(this, options);
    }

    if(_.isObject(this.collection)) {
      this.listenTo(this.collection, 'sync sort', this.render);
      this.listenTo(this.collection, 'error', this.handleSyncError);
    }

    if(_.isObject(this.model)) {
      this.listenTo(this.model, 'sync', this.render);
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

  error: function(message) {
    this.alert(message, 'danger');
  },

  warning: function(message) {
    this.alert(message, 'warning');
  },

  success: function(message) {
    this.alert(message, 'success');
  },

  alert: function(message) {
    var level = arguments[1] || 'info';
    $('#flash').html(alert_template({ level: level, message: message }));
  },

  hasRole: function(role) {
    return _.contains(this.app.config.user.meta.roles, role);
  },

  hook: function() {
    var args = Array.prototype.slice.call(arguments),
        name = args.shift();
    logger.debug('hook ' + name);
    this.trigger(name, args);
    if(_.isFunction(this[name])) { return this[name].apply(this, args); }
  }
});

