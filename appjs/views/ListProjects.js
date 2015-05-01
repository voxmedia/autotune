"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('../models'),
    FormView = require('./FormView');

module.exports = FormView.extend({
  template: require('../templates/project_list.ejs'),
  handleUpdateAction: function(eve) {
    var $btn = $(eve.currentTarget),
    model_class = $btn.data('model'),
    model_id = $btn.data('model-id'),
    inst = new models[model_class]({id: model_id});

    inst.updateSnapshot()
      .done(_.bind(function() {
        this.success('Upgrading the project to use the newest blueprint');
        inst.fetch();
      }, this))
      .fail(_.bind(this.handleRequestError, this));
  },
  handleBuildAction: function(eve) {
    var $btn = $(eve.currentTarget),
    model_class = $btn.data('model'),
    model_id = $btn.data('model-id'),
    inst = new models[model_class]({id: model_id});

    inst.build()
      .done(_.bind(function() {
        this.success('Building project');
        inst.fetch();
      }, this))
      .fail(_.bind(this.handleRequestError, this));
  }
});
