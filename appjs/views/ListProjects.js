"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('../models'),
    BaseView = require('./BaseView');

module.exports = BaseView.extend({
  template: require('../templates/project_list.ejs'),

  afterInit: function() {
    this.listenTo(this.collection, 'update', this.render);
  }
}, require('./mixins/actions'), require('./mixins/form') );
