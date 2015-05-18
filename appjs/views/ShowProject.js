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
    if( this.model.get('status') === 'built' ) {
      _.defer(_.bind(function() {
        this.pymParent = new pym.Parent('preview', this.model.get('preview_url'), {});
        $.get(this.model.get('preview_url') + 'embed.txt',
              function(data, status) { $('#embed textarea').text( data ); });
      }, this));
    }
  },

  handleUpdateAction: function(eve) {
    var $btn = $(eve.currentTarget);

    this.model.updateSnapshot()
      .done(_.bind(function() {
        this.success('Upgrading the project to use the newest blueprint');
        this.model.fetch();
      }, this))
      .fail(_.bind(this.handleRequestError, this));
  },

  handleBuildAction: function(eve) {
    var $btn = $(eve.currentTarget);

    this.model.build()
      .done(_.bind(function() {
        this.success('Building project');
        this.model.fetch();
      }, this))
      .fail(_.bind(this.handleRequestError, this));
  },

  handleBuildAndPublishAction: function(eve) {
    var $btn = $(eve.currentTarget);

    this.model.buildAndPublish()
      .done(_.bind(function() {
        this.success('Publishing project');
        this.model.fetch();
      }, this))
      .fail(_.bind(this.handleRequestError, this));
  }
});
