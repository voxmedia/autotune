"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('../models'),
    BaseView = require('./BaseView');

module.exports = BaseView.extend({
  template: require('../templates/blueprint_chooser.ejs')
}, require('./mixins/actions'), require('./mixins/form') );
