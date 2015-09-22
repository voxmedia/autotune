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
    Alpaca = require('./vendor/alpaca'),
    // Load our components and run the app
    Router = require('./router'),
    Listener = require('./listener'),
    logger = require('./logger'),
    views = require('./views'),
    models = require('./models');

// required to make Backbone work in browserify
Backbone.$ = $;

// Cause there doesn't seem to be a better way to set defaults for Alpaca
Alpaca.RuntimeView.prototype.toolbarSticky = true;

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
  this.themes.reset(config.themes);
  delete config.themes;

  this.tags = new Backbone.Collection();
  this.tags.reset(config.tags);
  delete config.tags;

  this.user = new Backbone.Model(config.user);
  delete config.user;

  this.blueprints = new models.BlueprintCollection();
  this.projects = new models.ProjectCollection();

  // Initialize server event listener
  this.listener = new Listener();
  this.listenTo(this.listener, 'stop', this.handleListenerStop, this);
  this.listener.start();

  this.config = config;

  if ( this.isDev() ) { logger.level = 'debug'; }

  // Initialize top-level view
  this.view = new views.Application({ app: this });

  // Initialize routing
  this.router = new Router({ app: this });

  // Start the app once the top-level view is rendered
  var view = this.view, app = this;
  this.view.render().then(function() {
    $('body').prepend(view.$el);
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
      this.listener.cancelStop();
      // Proxy the event on the app object
      this.trigger('focus');
    }, this));

    $(window).on('blur', _.bind(function(){
      this.hasFocus = false;
      logger.debug('App lost focus');
      // Tell the listener to time out in 20 seconds
      this.listener.stopAfter(200);
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
    this.view.alert('Reload to see changes', 'notice', true);
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
