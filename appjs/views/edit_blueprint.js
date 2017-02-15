"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('../models'),
    logger = require('../logger'),
    BaseView = require('./base_view');

var EditBlueprint = BaseView.extend(require('./mixins/actions'), require('./mixins/form'), {
  template: require('../templates/blueprint.ejs'),
  events: {
    'change :input': 'stopListeningForChanges'
  },

  afterInit: function() {
    this.on('load', function() {
      this.listenTo(this.app, 'loadingStart', this.stopListeningForChanges, this);
      this.listenTo(this.app, 'loadingStop', this.listenForChanges, this);
    }, this);

    this.on('unload', function() {
      this.stopListening(this.app);
      this.stopListeningForChanges();
    }, this);
  },

  listenForChanges: function() {
    if ( !this.model.isNew() && !this.listening ) {
      logger.debug('Start listening for changes');
      this.listenTo(this.app.messages,
                    'change:blueprint:' + this.model.id,
                    this.updateStatus, this);
      this.listening = true;
    }
  },

  stopListeningForChanges: function() {
    logger.debug('Stop listening for changes');
    this.stopListening(this.app.messages);
    this.listening = false;
  },

  updateStatus: function(data) {
    var status = data.status;
    logger.debug('Update blueprint status: ' + status);
    this.model.set('status', status);
    this.render();
  },

  beforeRender: function() {
    this.stopListeningForChanges();
  },

  afterRender: function() {
    var $form = this.$el.find('#new-blueprint');
    $($form).keypress(function(event){
      if (event.keyCode === 10 || event.keyCode === 13){
        event.preventDefault();
      }
    });
  }
} );

module.exports = EditBlueprint;
