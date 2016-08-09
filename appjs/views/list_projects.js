"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('../models'),
    BaseView = require('./base_view');

module.exports = BaseView.extend(require('./mixins/actions'), require('./mixins/form'), {
  template: require('../templates/project_list.ejs'),

  afterInit: function() {
    this.listenForChanges();
  },

  afterRender: function() {
    var fixInputSizing = function() {
      var childWidth = 0;
      var defaultWidth = $('.selectize-input').children('input').innerWidth();
      $.each($('.selectize-dropdown-content').children(), function(k,v){
        if ($(this).innerWidth() > childWidth) {
          childWidth = $(this).innerWidth();
        }
      });
      $('.selectize-input').innerWidth(childWidth);
      $('.selectize-input').children('input').innerWidth(childWidth);
    };

    $('.selectize-target').selectize({
      highlight: false,
      onDropdownOpen: function(){
        fixInputSizing();
      },
      onType: function() {
        fixInputSizing();
      }
    });
  },

  listenForChanges: function() {
    this.listenTo(this.app.listener, 'change:project',
                  this.updateStatus, this);
  },

  stopListeningForChanges: function() {
    this.stopListening(this.app.listener);
  },

  updateStatus: function(data) {
    var model = this.collection.get(data.id);
    if ( model ) {
      model.set('status', data.status);
      this.render();
    }
  }
} );
