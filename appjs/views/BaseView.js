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

  initialize: function() {
    var args = Array.prototype.slice.call(arguments);
    this.hook('beforeInit', args);

    if(_.isObject(this.collection)) {
      this.collection
        .on("sync sort", this.render, this)
        .on("error", this.logError, this);
    }

    if(_.isObject(this.model)) {
      this.model
        .on("sync change", this.render, this)
        .on("error", this.logError, this);
    }

    if(_.isObject(args[0]['query'])) { this.query = args[0].query; }

    this.render();

    this.hook('afterInit', args);
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
    var obj = {};
    if(_.isObject(this.collection)) { obj.collection = this.collection; }
    else if(_.isObject(this.model)) { obj.model = this.model; }

    if(_.isObject(this.query)) { obj.query = this.query; }

    this.hook('beforeRender', obj);

    this.$el.html(this.template(obj));

    this.hook('afterRender', obj);

    return this;
  },

  logError: function(model_or_collection, resp, options) {
    console.log(arguments);
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

  hook: function() {
    var args = Array.prototype.slice.call(arguments),
        name = args.shift();
    console.log('hook ' + name);
    if(_.isFunction(this[name])) { return this[name].apply(this, args); }
    this.trigger(name, args);
  }
});

