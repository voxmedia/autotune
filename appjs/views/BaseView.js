"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('../models'),
    camelize = require('underscore.string/camelize'),
    alert_template = require('../templates/alert.ejs');

module.exports = Backbone.View.extend({
  events: {
    'click a': 'handleLink'
  },

  initialize: function(options) {
    this.hook('beforeInit', options);

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
    var href = $(eve.currentTarget).attr('href');
    if (!/^(https?:\/\/|#)/.test(href) && !eve.metaKey && !eve.ctrlKey) {
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
    this.app.debug(tmplObj);
    this.$el.html(tmpl(tmplObj));
    this.app.view.spinStop();
  },

  error: function(message) {
    this.alert(message, 'danger');
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
    console.log('hook ' + name);
    if(_.isFunction(this[name])) {
      _.defer(
        function(view, args) {
          view[name].apply(view, args);
          view.trigger(name, args);
        }, this, args);
    }
  }
});

