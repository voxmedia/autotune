"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('../models'),
    FormView = require('./FormView');

module.exports = FormView.extend({
  template: require('../templates/blueprint.ejs'),
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
});
