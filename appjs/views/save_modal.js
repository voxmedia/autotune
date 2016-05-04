"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('../models'),
    BaseView = require('./base_view');

module.exports = BaseView.extend({

    id: 'SaveModal',
    className: 'modal fade hide',
    template: require('../templates/modal.ejs'),
    events: {
      'hidden': 'teardown'
    },

    initialize: function() {
      _.bindAll(this, 'show', 'teardown', 'render', 'renderView');
      this.render();
    },

    show: function() {
      this.$el.modal('show');
    },

    teardown: function() {
      this.$el.data('modal', null);
      this.remove();
    },

    render: function() {
      this.getTemplate(this.template, this.renderView);
      return this;
    },

    renderView: function(template) {
      this.$el.html(template());
      this.$el.modal({show:false}); // dont show modal on instantiation
    }
 });
