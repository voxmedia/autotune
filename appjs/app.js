/*
 * autotune
 * https://github.com/voxmedia/autotune
 *
 * @file Top level class for the Autotune admin UI
 */

// Load jQuery and Backbone, make sure Backbone uses jQuery
var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    bootstrap = require('bootstrap'),
    moment = require('moment'),
    Alpaca = require('./alpaca_patches'),
    Datepicker = require('eonasdan-bootstrap-datetimepicker'),
    Spectrum = require('spectrum-colorpicker'),
    Selectize = require('../vendor/assets/javascripts/selectize'),
    // Load our components and run the app
    Router = require('./router'),
    Messages = require('./messages'),
    logger = require('./logger'),
    views = require('./views'),
    models = require('./models');

// required to make Backbone work in browserify
Backbone.$ = $;

var oldLoadUrl = Backbone.history.loadUrl;
Backbone.history.loadUrl = function(fragment) {
  var view = window.app.view.currentView;
  // This is used to override the default back button functionality. If the project has unsaved changes,
  // this will push the user back to the edit_project page and then trigger navigate, which will display
  // the save notification modal. Fragment only comes back as undefined when the back button is clicked.
  if ( view && view.hasUnsavedChanges && view.hasUnsavedChanges() && typeof fragment === 'undefined' ) {
    window.history.forward();
    view.app.router.navigate(window.location.pathname, { trigger: true });
  } else {
    oldLoadUrl.call(Backbone.history, fragment);
  }
};

/**
 * Autotune admin UI
 * @constructor
 * @param {Object} config - Configure the admin UI
 * @param {string} config.env - Environment (production, staging or development)
 * @param {Object} config.user - Current user info
 * @param {Object[]} config.themes - Possible project themes
 * @param {Object[]} config.tags - Blueprint tags
 * @param {Object[]} config.blueprints - Blueprints
 * @param {Object[]} config.projects - Projects
 */
function App(config) {
  this.themes = new Backbone.Collection();
  this.themes.reset(config.available_themes);
  delete config.available_themes;

  this.tags = new Backbone.Collection();
  this.tags.reset(config.tags);
  delete config.tags;

  this.user = new Backbone.Model(config.user);
  delete config.user;

  this.designerGroups = new Backbone.Collection();
  this.designerGroups.reset(config.designer_groups);
  delete config.designer_groups;

  this.config = config;

  if ( this.isDev() ) { logger.level = 'debug'; }

  this.blueprints = new models.BlueprintCollection();
  this.projects = new models.ProjectCollection();
  this.editableThemes = new models.ThemeCollection();

  // Initialize top-level view
  this.view = new views.Application({ app: this });

  // Initialize server event listener
  this.messages = new Messages({startDate: new Date(Date.parse(config.date)).getTime()/1000});
  this.listenTo(this.messages, 'stop', this.handleListenerStop);
  this.listenTo(this.messages, 'error', this.handleListenerError);
  this.listenTo(this.messages, 'open', this.handleListenerStart);
  this.listenTo(this.messages, 'alert', this.handleAlertMessage);
  this.messages.start();

  // Initialize routing
  this.router = new Router({ app: this });

  // Start the app once the top-level view is rendered
  var view = this.view, app = this;
  this.view.render().then(function() {
    $('#autotune-main-body').prepend(view.$el);
    app.trigger( 'loadingStart' );
    Backbone.history.start({ pushState: true });
  });

  // Handle application focus
  this.hasFocus = true;
  if ( typeof(window) !== 'undefined' ) {
    $(window).on('focus', _.bind(function(){
      this.hasFocus = true;
      logger.debug('App has focus');
      // Tell the listener to cancel the timeout
      this.messages.cancelStop();
      // Proxy the event on the app object
      this.trigger('focus');
    }, this));

    $(window).on('blur', _.bind(function(){
      this.hasFocus = false;
      logger.debug('App lost focus');

      if ( !this.isDev() ) {
        // Tell the listener to time out in 8mins
        this.messages.stopAfter(8*60);
      }

      // Proxy the event on the app object
      this.trigger('blur');
    }, this));
  }
}

_.extend(App.prototype, Backbone.Events, {
  /**
   * Is the app running in dev mode
   * @return {bool}
   */
  isDev: function() {
    return this.config.env === 'development' || this.config.env === 'staging';
  },

  /**
   * Log an analytic event
   * @param {string} type - Event type (pageview)
   */
  analyticsEvent: function() {
    if ( typeof(window) !== 'undefined' && window.ga ) {
      var ga = window.ga;
      if ( arguments[0] === 'pageview' ) {
        ga('send', 'pageview');
      }
    }
  },

  /**
   * Do something when the listener shuts down
   **/
  handleListenerStop: function() {
    this.view.warning('Reload to see changes', true);
  },

  /**
   * Do something when the listener errors out
   **/
  handleListenerError: function(error) {
    var msg;
    this.view.clearNotification( 'Reload to see changes' );
    if ( error === 'auth' ) {
      msg = 'Your session has expired.';
    } else if (error) {
      msg = 'There was a problem connecting to the server ('+error+').';
    } else {
      msg = 'There was a problem connecting to the server.';
    }
    this.view.error(msg, true);
  },

  /**
   * Do something when the listener starts
   **/
  handleListenerStart: function() {
    this.view.clearNotification( 'Reload to see changes' );
  },

  /**
   * Display an alert message to the user
   **/
  handleAlertMessage: function(data) {
    this.view.alert(data.text, data.level, data.timeout);
  },

  /**
   * Check if the user has a certian role
   * @param {string} role - Role name
   * @returns {boolean}
   **/
  hasRole: function(role) {
    return _.contains(this.user.get('meta').roles, role) ||
          this.user.get('meta').roles[role];
  }

});

module.exports = App;

if ( typeof(window) !== 'undefined' ) {
  // Make App a global so we can initialize from our webpage
  window.App = App;
  // Make libraries accessible to global scope for console use
  window.Backbone = Backbone;
  window.$ = $;
  window._ = _;
  window.moment = moment;
  window.Alpaca = Alpaca;
}
