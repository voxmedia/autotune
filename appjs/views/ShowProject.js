"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('../models'),
    FormView = require('./FormView'),
    pym = require('pym.js');

module.exports = FormView.extend({
  template: require('../templates/project.ejs'),
  afterRender: function() {
    _.defer(_.bind(function() {
      this.pymParent = new pym.Parent('preview', this.model.get('preview_url'), {});
    }, this));
  },
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
  },
  handleBuildAndPublishAction: function(eve) {
    var $btn = $(eve.currentTarget),
    model_class = $btn.data('model'),
    model_id = $btn.data('model-id'),
    inst = new models[model_class]({id: model_id});

    inst.buildAndPublish()
      .done(_.bind(function() {
        this.success('Publishing project');
        inst.fetch();
      }, this))
      .fail(_.bind(this.handleRequestError, this));
  }
});
