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

// Make libraries accessible to global scope, for console use and error logging
window.Backbone = Backbone;
window.$ = Backbone.$ = $;
window._ = _;

var bootstrap = require('bootstrap'),
    Alpaca = require('./vendor/alpaca');

// Load our components and run the app
var Router = require('./router');

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
window.App = function(config) {
  this.config = config;
  this.router = new Router({app: this});
  this.msgListener = null;
  this.has_focus = true;

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
};

_.extend(window.App.prototype, {
  /**
   * Is the app running in dev mode
   * @return {bool}
   */
  isDev: function() {
    return this.config.env === 'development' || this.config.env === 'staging';
  },

  /**
   * Put an informational message into the log
   */
  log: function() {
    console.log.apply(console, arguments);
  },

  /**
   * Put a debugging message into the log
   */
  debug: function() {
    if (this.isDev()) { console.debug.apply(console, arguments); }
  },

  /**
   * Put an error message into the log
   */
  error: function() {
    console.error.apply(console, arguments);
  },

  /**
   * Log an analytic event
   * @param {string} type - Event type (pageview)
   */
  analyticsEvent: function() {
    if ( window.ga ) {
      var ga = window.ga;
      if ( arguments[0] === 'pageview' ) {
        ga('send', 'pageview');
      }
    }
  },

  /**
   * Initialize the server-side events listener
   */
  startListeningForChanges: function(){
    if(this.msgListener && (this.msgListener.readyState === this.msgListener.OPEN || this.msgListener.readyState === this.msgListener.CONNECTING)){
      return;
    }

    if(!this.has_focus){
      this.view.warning("Stopped automatic status update due to inactivity. Refresh page to see recent changes.");
      return;
    }

    this.debug('Init server event listener');
    this.msgListener = new window.EventSource('/changemessages');

    this.msgListener.addEventListener('change', _.bind(function(evt) {
      var msg = JSON.parse(evt.data);
      var refresh = false;

      // Don't proceed if the change is on a different type of data
      if(!this.dataToRefresh || (msg.type !== this.dataType)){
        return;
      }

      // check if the changed object id is in the activedata
      if(this.dataToRefresh instanceof Backbone.Collection){
        refresh = _.where(this.dataToRefresh.models, {id: msg.id}).length !== 0;
      }
      else {
        refresh = this.dataToRefresh.get("id") === msg.id;
      }

      if(refresh){
        this.debug('server event; updating data');
        if ( this.dataQuery ) {
          this.dataToRefresh.fetch({data: this.dataQuery});
        } else {
          this.dataToRefresh.fetch();
        }
      }
    }, this));

    this.msgListener.onerror = _.bind(function(){
      if(!this.sseRetryCount){
        this.sseRetryCount = 0;
      }
      this.sseRetryCount++;
      this.debug('Could not connect to event stream "changemessages"');
      if(this.msgListener){
        this.msgListener.close();
      }
      if(this.sseRetryCount <= 10){
        this.sseRetryTimeout = setTimeout(_.bind(this.startListeningForChanges,this), 2000);
      }
      if(this.sseRetryCount > 2){
        this.view.warning("Could not get automatic status updates. Retrying...");
      }
      if(this.sseRetryCount >=10){
        this.view.error("Could not get automatic status updates. Refresh page to see recent changes.");
      }
    },this);

    this.msgListener.onopen = function(){
      this.sseRetryCount = 0;
    };
  },

  /**
   * Disable the server side event listener
   */
  stopListeningForChanges: function(ignoreFocus){
    this.debug('Checking for focus');
    if(ignoreFocus || this.has_focus){
      return;
    }
    if(this.msgListener && this.msgListener.readyState === this.msgListener.OPEN){
      this.debug('Close event listener');
      this.msgListener.close();      
      this.view.warning("Stopped automatic status update due to inactivity. Refresh page to see recent changes.");
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
