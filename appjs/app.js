/*
 * autotune
 * https://github.com/voxmedia/autotune
 *
 * @file Top level class for the Autotune admin UI
 */

// Load jQuery and Backbone, make sure Backbone uses jQuery
var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone');

var bootstrap = require('bootstrap'),
    Alpaca = require('./vendor/alpaca');

// required to make Backbone work
Backbone.$ = $;

// Load our components and run the app
var Router = require('./router'),
    Listener = require('./listener'),
    logger = require('./logger');

/**
 * Autotune admin UI
 * @constructor
 * @param {Object} config - Configure the admin UI
 * @param {string} config.env - Environment (production, staging or development)
 * @param {string[]} config.project_statuses - Possible project statuses
 * @param {string[]} config.project_themes - Possible project themes
 * @param {int[]} config.project_blueprints - Blueprint IDs used by existing projects
 * @param {string[]} config.blueprints_tags - Blueprint tags
 * @param {Object} config.user - Current user info
 */
function App(config) {
  _.extend(this, Backbone.Events);

  this.themes = new Backbone.Collection();
  this.themes.reset(config.themes);
  delete config.themes;

  this.config = config;
  this.router = new Router({app: this});
  this.msgListener = null;
  this.has_focus = true;

  if ( this.isDev() ) { logger.level = 'debug'; }

  Backbone.history.start({pushState: true});

  if ( window.EventSource ) {
    $(window).on('focus', _.bind(function(){
      this.has_focus = true;
      if(this.sseClosingTimeout){
        this.debug('Clearing sse closing timeout');
        clearTimeout(this.sseClosingTimeout);
      }
    }, this));

    $(window).on('blur', _.bind(function(){
      this.has_focus = false;
      this.sseClosingTimeout = setTimeout(_.bind(this.stopListeningForChanges, this), 10000);
    }, this));

    this.startListeningForChanges();
  }
}

_.extend(App.prototype, {
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
    if ( window && window.ga ) {
      var ga = window.ga;
      if ( arguments[0] === 'pageview' ) {
        ga('send', 'pageview');
      }
    }
  },

  /**
   * Provide references to the models or collections that the event listener should refresh
   * @param {string} type - Type of data to refresh (blueprint, project)
   * @param {Object} data - Backbone object to refresh
   * @param {Object} query - Optional query to use in the refresh
   */
  setActiveData: function(type, data, query){    
    this.dataType = type;
    this.dataToRefresh = data;
    this.dataQuery = query;
  }
});

module.exports = App;

// Make libraries accessible to global scope, for console use and error logging
if ( _.isObject(window) ) {
  window.App = App;
  window.Backbone = Backbone;
  window.$ = $;
  window._ = _;
}
