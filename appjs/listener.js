"use strict";

var _ = require('underscore'),
    Backbone = require('backbone'),
    logger = require('./logger');

function Listener(opts) {
  _.extend(this, Backbone.Events);
}

_.extend(Listener.prototype, {
  /**
   * Initialize the server-side events listener
   */
  start: function(){
    if ( this.hasStatus('open', 'connecting') ) { return; }

    logger.debug('Init server event listener');
    this.conn = new window.EventSource('/changemessages');

    this.conn.addEventListener('change', _.bind(function(evt) {
      logger.debug('Fire change event', evt.data);
      this.trigger('change', JSON.parse(evt.data));
    }, this));

    this.conn.onerror = _.bind(function(){
      if(!this.sseRetryCount){
        this.sseRetryCount = 0;
      }
      this.sseRetryCount++;
      logger.debug('Could not connect to event stream "changemessages"');
      if(this.conn){
        this.conn.close();
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

    this.conn.onopen = function(){
      this.sseRetryCount = 0;
    };
  },

  /**
   * Disable the server side event listener
   */
  stop: function stop() {
    if ( this.hasStatus('open') ) {
      logger.debug('Close event listener');
      this.conn.close();
      this.trigger('stop');
    }
  },

  hasStatus: function hasStatus() {
    var iteratee = function(m, i) {
      return m || this.conn.readyState === i;
    };
    return this.conn && _.reduce( arguments, _.bind(iteratee, this), false );
  }
});

module.exports = Listener;
