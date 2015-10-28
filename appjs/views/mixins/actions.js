"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    camelize = require('underscore.string/camelize'),
    pym = require('pym.js'),
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
    var inst, view = this, app = this.app,
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
      if ( this.collection ) {
        logger.debug('load model from collection');
        inst = this.collection.get( model_id );
      }

      if ( !inst ) {
        inst = new models[model_class]({id: model_id});
      }
    } else {
      inst = this.model;
    }

    if ( action_confirm && !window.confirm( action_confirm ) ) { return; }

    Promise.resolve( inst[camelize(action)]() )
      .then(function(resp) {
        app.view.alert(action_message, 'success', false, 4000);

        switch (action) {
          case 'build':
            app.view.alert(
              'Building... This might take a moment.', 'notice', false, 16000);
            break;
          case 'destroy':
            if ( view.collection ) {
              logger.debug('Removing '+model_id+' from collection');
              view.collection.remove(model_id);
            }
            break;
        }

        if ( next === 'show' ) {
          Backbone.history.navigate( inst.url(), {trigger: true} );
        } else if ( next === 'reload' ) {
          return view.render();
        } else if ( next ) {
          Backbone.history.navigate( next, {trigger: true} );
        }
      }).catch(function(error) {
        view.handleRequestError( error );
        if ( $btn.hasClass('btn') ) { $btn.button( 'reset' ); }
        app.trigger( 'loadingStop' );
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
