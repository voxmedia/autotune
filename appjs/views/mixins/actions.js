"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    camelize = require('underscore.string/camelize'),
    models = require('../../models'),
    logger = require('../../logger'),
    helpers = require('../../helpers');

/* Actions view mixin
 * Generic handler for action buttons that do something to a model.
 */
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

    // if(action === 'build-and-publish' && view.hasUnsavedChanges()){
    //   view.$('#projectForm form').submit();
    // }

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
    logger.debug(inst);

    if ( action_confirm && !window.confirm( action_confirm ) ) { return; }

    Promise.resolve( inst[camelize(action)]() )
      .then(function(resp) {
        if(action_message){
          app.view.success(action_message, 8000);
        }

        switch (action) {
          case 'build-and-publish':
            view.model.set('status', 'building');
            app.view.warning(
              'Publishing... This might take a moment.', 8000);
            break;
          case 'build':
            app.view.warning(
              'Building... This might take a moment.', 8000);
            break;
          case 'save':
            if(view.hasUnpublishedUpdates() && view.hasStatus('built')){
              app.view.info(model_class+' updates saved but not published');
            } else {
              app.view.success(model_class+' updates saved');
            }
            break;
          case 'destroy':
            if ( view.collection ) {
              logger.debug('Removing '+model_id+' from collection');
              view.collection.remove(model_id);
            }
            break;
        }

        if ( next === 'show' ) {
          this.app.router.navigate( inst.url(), {trigger: true} );
        } else if ( next === 'reload' ) {
          logger.debug('got next as reload', view.model.get('status'));
          return view.render();
        } else if ( next ) {
          this.app.router.navigate( next, {trigger: true} );
        } else {
          if ( $btn.hasClass('btn') ) { $btn.button( 'reset' ); }
          app.trigger( 'loadingStop' );
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
  }
};
