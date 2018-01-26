"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('../models'),
    BaseView = require('./base_view');

module.exports = BaseView.extend(require('./mixins/actions'), require('./mixins/form'), {
  template: require('../templates/theme_list.ejs'),

  afterInit: function() {
    this.listenForChanges();
  },

  listenForChanges: function() {
    this.listenTo(this.app.listener, 'change:theme',
                  this.updateStatus, this);
  },

  stopListeningForChanges: function() {
    this.stopListening(this.app.listener);
  },

  updateStatus: function(data) {
    var model = this.collection.get(data.id);
    if ( model ) {
      model.set('status', data.status);
      this.render();
    }
  }
} );
