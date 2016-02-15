"use strict";

module.exports = {
  /**
   * What stuff should we log?
   */
  level: 'log',

  /**
   * Put an informational message into the log
   */
  log: function log() {
    console.log.apply(console, arguments);
    return arguments;
  },

  /**
   * Put a debugging message into the log
   */
  debug: function debug() {
    if (this.level === 'debug') { 
      console.debug.apply(console, arguments);
      return true; 
    } else {
      return false;
    }
  },

  /**
   * Put an error message into the log
   */
  error: function error() {
    console.error.apply(console, arguments);
    return arguments;
  }
};
