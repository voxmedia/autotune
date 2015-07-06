"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    camelize = require('underscore.string/camelize'),
    models = require('../models'),
    logger = require('../logger'),
    helpers = require('../helpers');

module.exports = {
  events: {
    'click button[data-action],a[data-action]': 'handleAction',
  },

  handleAction: function(eve) {
    eve.preventDefault();
    eve.stopPropagation();
    var inst, view = this,
        $btn = $(eve.currentTarget),
        action = $btn.data('action'),
        action_confirm = $btn.data('action-confirm'),
        action_message = $btn.data('action-message'),
        next = $btn.data('action-next'),
        model_class = $btn.data('model'),
        model_id = $btn.data('model-id');

    this.app.trigger('loadingStart');
    $btn.button('loading');

    if ( model_class && model_id ) {
      inst = new models[model_class]({id: model_id});
    } else {
      inst = this.model;
    }

    if ( action_confirm && !window.confirm( action_confirm ) ) {
      return;
    }

    Promise.resolve( inst[camelize(action)]() )
      .then(function(resp) {
        view.app.view.success( action_message );
        $btn.button( 'reset' );
        view.app.trigger( 'loadingStop' );
        if ( next === 'show' ) {
          Backbone.history.navigate( view.model.url(), {trigger: true} );
        } else if ( next ) {
          Backbone.history.navigate( next, {trigger: true} );
        }
      }).catch(function(error) {
        view.handleRequestError( error );
      });
  },

  handleRequestError: function(xhr){
    if ( xhr.statusText === 'Bad Request' ) {
      var data = $.parseJSON( xhr.responseText );
      this.app.view.error( data.error );
    } else {
      this.app.view.error( 'Something bad happened... Please reload and try again' );
    }
    logger.error("REQUEST FAILED!!", xhr);
  },

};
