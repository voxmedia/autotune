"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    PNotify = require('pnotify'),
    models = require('../models'),
    logger = require('../logger'),
    BaseView = require('./BaseView');

require('pnotify/src/pnotify.buttons');

module.exports = BaseView.extend({
  className: 'container-fluid',
  template: require('../templates/application.ejs'),
  notifications: [],
  alertDefaults: {
    addclass: "stack-bottomright",
    stack: { dir1: "up", dir2: "left", firstpos1: 25, firstpos2: 25 },
    buttons: { sticker: false }
  },

  display: function(view) {
    if ( this.currentView ) { this.currentView.unload(this); }
    this.currentView = view;
    this.currentView.load(this);
    logger.debug('displaying view', view, this.$('#main'));
    this.$('#main').empty().append(view.$el);
    return this;
  },

  spinStart: function() {
    this.$('#spinner').show();
    return this;
  },

  spinStop: function() {
    _.defer(_.bind(function() {
      this.$('#spinner').fadeOut('fast');
    }, this));
    return this;
  },

  setTab: function(name) {
    this.$('#nav [data-tab]').removeClass('active');
    if(name) { this.$('#nav [data-tab='+name+']').addClass('active'); }
    return this;
  },

  error: function(message) {
    return this.alert(message, 'error');
  },

  warning: function(message) {
    return this.alert(message, 'notice');
  },

  success: function(message) {
    return this.alert(message, 'success');
  },

  alert: function(message, level, permanent) {
    var opts = _.defaults({
      text: message,
      type: level || 'info'
    }, this.alertDefaults);

    if ( permanent ) {
      _.extend(opts, {
        buttons: { close: false, sticker: false },
        hide: false
      });
      this.notifications.push( new PNotify(opts) );
    } else {
      new PNotify(opts);
    }
    return this;
  },

  clearError: function() {
    _.each(this.notifications, function(n) {
      if ( n.remove ) { n.remove(); }
    });
    this.notifications = [];
    return this;
  }
});
