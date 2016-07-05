"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    PNotify = require('pnotify'),
    logger = require('../logger'),
    helpers = require('../helpers'),
    BaseView = require('./base_view');

// Set PNotify to use bootstrap
PNotify.prototype.options.styling = "bootstrap3";
// Load PNotify buttons component
require('pnotify/src/pnotify.buttons');
require('pnotify/src/pnotify.callbacks');

var Application = BaseView.extend(require('./mixins/links.js'), {
  //className: 'container-fluid',
  template: require('../templates/application.ejs'),
  alertDefaults: {
    // addclass: "stack-bottomright",
    stack: {"dir1": "down", "dir2": "right", "push": "top", "spacing1": 0, "spacing2": 0},
    addclass: "center-top-notification",
    width: '100%',
    buttons: { sticker: false },
    animate_speed: 0
  },
  events: {
    'click ul.navbar-nav li a': 'toggleNav',
    'click #savePreview': 'savePreview'
  },

  afterInit: function() {
    // Show or hide spinner on loading events
    this.listenTo(this.app, 'loadingStart', this.spinStart, this);
    this.listenTo(this.app, 'loadingStop', this.spinStop, this);
  },

  display: function(view) {
    if ( this.currentView ) { this.currentView.unload(this); }
    this.currentView = view;
    this.currentView.load(this);
    logger.debug('displaying view', view, this.$('#main'));
    if ( window ) { $(window).scrollTop(0); }
    this.$('#main').empty().append(view.$el);
    return this;
  },

  display404: function() {
    this.$('#main').empty().append(
      helpers.render( require('../templates/not_found.ejs') ));
  },

  display403: function() {
    this.$('#main').empty().append(
      helpers.render( require('../templates/not_allowed.ejs') ));
  },

  display500: function(status, message) {
    this.$('#main').empty().append(
      helpers.render( require('../templates/error.ejs'), {status: status, message: message} ));
  },

  displayError: function(code, status, message) {
    if (code === 404) {
      this.display404();
    } else if (code === 403) {
      this.display403();
    } else {
      this.display500(status, message);
    }
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

  error: function(message, wait) {
    return this.alert(message, 'error', wait);
  },

  warning: function(message, wait) {
    return this.alert(message, 'notice', wait);
  },

  success: function(message, wait) {
    return this.alert(message, 'success', wait);
  },

  info: function(message, wait) {
    return this.alert(message, 'info', wait);
  },

  alert: function(message, level, wait) {
    var page = this;
    this.alertDefaults.stack.context = this.$('#alert-area');
    var noti,
        opts = _.defaults({
          text: message,
          type: level || 'info',
          delay: 8000,
          before_open: function(thing){
            page.$('#alert-area').parent().addClass('has-alert');
          },
          after_close: function(thing){
            page.$('#alert-area').parent().removeClass('has-alert');
          }
        }, this.alertDefaults);

    if ( _.isNumber(wait) && wait > 0 ) {
      opts['delay'] = wait;
    } else if ( wait === true || wait === 'permanent' || wait === 0 ) {
      _.extend(opts, {
        buttons: { closer: false, sticker: false },
        hide: false
      });
    }
    noti = this.findNotification( message );

    return noti || new PNotify(opts);
  },

  findNotification: function(message) {
    return _.find(PNotify.notices, function(notify) {
      return notify.options.text === message;
    } );
  },

  clearNotification: function(message) {
    if ( message ) {
      return this.findNotification( message );
    } else {
      return PNotify.removeAll();
    }
  },

  toggleNav: function(event){
    logger.debug('toggleNav', event);
    if($('#navbar-collapse').hasClass('in')){
      $('#navbar-collapse').collapse('toggle');
    }
  },

  savePreview: function(){
    this.currentView.doSubmit(this.$('#projectForm form'));
  }
});

module.exports = Application;
