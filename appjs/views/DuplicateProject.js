"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('../models'),
    BaseView = require('./BaseView');

module.exports = BaseView.extend(require('./mixins/actions'), require('./mixins/form'), {
  template: require('../templates/project_duplicate.ejs'),

  afterInit: function() {
    this.listenTo(this.model, 'update', this.render);
  }
} );
