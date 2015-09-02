"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    camelize = require('underscore.string/camelize'),
    models = require('../../models'),
    logger = require('../../logger'),
    helpers = require('../../helpers');

module.exports = {
  events: {
    'click button[data-action], a[data-action]': 'handleAction'
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

    logger.debug('action-next-'+ next);
    logger.debug('action-' + action);
    this.app.trigger('loadingStart');
    if ( $btn.hasClass('btn') ) {
      $btn.button('loading');
    }

    if ( model_class && model_id ) {
      inst = new models[model_class]({id: model_id});
    } else {
      inst = this.model;
    }

    if ( action_confirm && !window.confirm( action_confirm ) ) { return; }

    Promise.resolve( inst[camelize(action)]() )
      .then(function(resp) {
        view.app.view.alert(action_message, 'success', false, 4000);

        if (action.indexOf('build') > -1){
          view.app.view.alert('Building... This might take a moment.', 'notice', false, 16000);
        }

        if ( next === 'show' ) {
          Backbone.history.navigate( view.model.url(), {trigger: true} );
        } else if ( next === 'reload' ) {
          view.render();
          Backbone.history.loadUrl();
        } else if ( next ) {
          Backbone.history.navigate( next, {trigger: true} );
        }
      }).catch(function(error) {
        view.handleRequestError( error );
      }).then(function() {
        if ( $btn.hasClass('btn') ) { $btn.button( 'reset' ); }
        view.app.trigger( 'loadingStop' );
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
