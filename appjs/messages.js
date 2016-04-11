"use strict";

var _ = require('underscore'),
    Backbone = require('backbone'),
    $ = require('jquery'),
    logger = require('./logger');

/**
 * Initialize the listener
 */
function Messages(opts) {
  this.config = _.defaults(opts || {}, {
    url: '/messages', checkInterval: 3, errorRetry: 3
  });

  this.errorStop = false;
  this.lastCheck = Date.now()/1000;
}

_.extend(Messages.prototype, Backbone.Events, {
  /**
   * Start the messages checker
   */
  start: function(){
    if ( this.paused ) { this.paused = false; }
    if ( this.interval ) { return; }
    if ( this.errorStop ) { return; }

    logger.debug('Starting messages now');
    this.interval = window.setInterval(
      _.bind(this._check, this),
      this.config.checkInterval*1000
    );
    this.trigger('open');

    this.errorCount = 0;

    return this;
  },

  /**
   * Disable messages
   */
  stop: function() {
    if ( !this.interval ) { return; }

    logger.debug('Stopping messages now');
    window.clearInterval(this.interval);
    this.interval = undefined;
    this.trigger('stop');
    return this;
  },

  stopAfter: function(seconds) {
    if ( !this.interval ) { return; }

    logger.debug('Stopping messages in ' + seconds);
    if ( this.stopTimeout ) { clearTimeout(this.stopTimeout); }
    this.stopTimeout = setTimeout(_.bind(this.stop, this), seconds*1000);
    return this;
  },

  cancelStop: function() {
    if ( !this.interval || !this.stopTimeout ) { return; }

    logger.debug('Canceling messages stop');
    clearTimeout(this.stopTimeout);
    return this;
  },

  pause: function() {
    logger.debug('Pausing messages');
    this.paused = true;
  },

  send: function(type, message) {
    return Promise.resolve( $.post(
      this.config.url+'/send', { type: type, message: message }, null, 'json'
    ) );
  },

  _check: function() {
    if ( this.paused ) { return; }

    var ts = this.lastCheck, self = this;
    this.lastCheck = Date.now()/1000;

    logger.debug('Checking messages... (app.messages.stop() to stop)');
    $.get(
      '/messages', { since: ts }, null, 'json'
    ).then(function( data ) {
      self.errorCount = 0;

      data.forEach(function(item) {
        logger.debug('message', item);

        self.trigger( 'message', item );
        self.trigger( item.type, item.data );

        if ( item.data.model ) {
          self.trigger( [item.type, item.data.model].join(':'), item.data );
        }

        if ( item.data.model && item.data.id ) {
          self.trigger(
            [item.type, item.data.model, item.data.id].join(':'),
            item.data
          );
        }

      });
    }, function( jqxhr, textStatus, error ) {
      if ( jqxhr.status === 401 || jqxhr.status === 403 ) {
        self.stop();
        self.trigger('error', 'auth');
        self.errorStop = true;
      } else {
        self.errorCount++;
        if ( self.errorCount >= self.errorRetry ) {
          self.stop();
          self.trigger('error', error);
          self.errorStop = true;
        }
        logger.error('Connection error', error);
      }
    });
  }
});

module.exports = Messages;
