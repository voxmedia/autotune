"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('../models'),
    BaseView = require('./base_view');

module.exports = BaseView.extend(require('./mixins/actions'), require('./mixins/form'), {
  template: require('../templates/blueprint_list.ejs'),

  afterInit: function() {
    this.listenForChanges();
  },

  listenForChanges: function() {
    this.listenTo(this.app.messages, 'change:blueprint',
                  this.updateStatus, this);
  },

  stopListeningForChanges: function() {
    this.stopListening(this.app.messages);
  },

  updateStatus: function(data) {
    var model = this.collection.get(data.id);
    if ( model ) {
      model.set('status', data.status);
      this.render();
    }
  },

  handleUpdateAction: function(eve) {
    var $btn = $(eve.currentTarget),
    model_class = $btn.data('model'),
    model_id = $btn.data('model-id'),
    inst = new models[model_class]({id: model_id});

    inst.updateRepo()
      .done(_.bind(function() {
        this.app.view.success('Updating blueprint repo');
        inst.fetch();
      }, this))
      .fail(_.bind(this.handleRequestError, this));
  }
} );
