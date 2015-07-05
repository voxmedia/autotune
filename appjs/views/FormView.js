"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('../models'),
    logger = require('../logger'),
    camelize = require('underscore.string/camelize'),
    BaseView = require('./BaseView');

module.exports = BaseView.extend({
  events: {
    'click a[href]': 'handleLink',
    'submit form': 'handleForm',
    'click button[data-action],a[data-action]': 'handleAction',
    'change select[data-auto-submit=true]': 'submitForm',
    'change :input': 'handleFormChange'
  },

  initialize: function(options) {
    BaseView.prototype.initialize.call(this, options);
  },

  handleForm: function(eve) {
    eve.preventDefault();
    eve.stopPropagation();

    this.app.trigger('loadingStart');
    logger.debug('handleForm');

    var inst, Model, view = this,
        $form = $(eve.currentTarget),
        values = this.formValues($form),
        model_class = $form.data('model'),
        model_id = $form.data('model-id'),
        action = $form.data('action'),
        next = $form.data('next');

    $form.find('[type=submit]').button('loading');

    if(model_class && action === 'new') {
      inst = new models[model_class]();
    } else if(_.isObject(this.model) && action === 'edit') {
      inst = this.model;
    } else if ($form.attr('method').toLowerCase() === 'get') {
      // if the method attr is `get` then we can navigate to that new
      // url and avoid any posting
      var basepath = $form.attr('action') || window.location.pathname;
      Backbone.history.navigate(
        basepath + '?' + $form.serialize(),
        {trigger: true});
      return;
    } else { throw "Don't know how to handle this form"; }

    return this.hook('beforeSubmit', $form, values, action, inst)
      .then(function() {
        inst.set(values);
        if(!view.formValidate(inst, $form)) {
          $form.find('[type=submit]').button('reset');
          logger.debug('form is not valid');
          throw 'Form is not valid';
        }

        logger.debug('form is valid, saving...');

        return Promise.resolve( inst.save() );
      }).then(function(data) {
        logger.debug('form finished saving');

        if ( action === 'new' ) {
          view.app.view.success('New '+model_class+' saved');
        } else {
          view.app.view.success(model_class+' updates saved');
        }

        if ( next === 'show' ) {
          Backbone.history.navigate(view.model.url(), {trigger: true});
        } else if ( next ) {
          Backbone.history.navigate(next, {trigger: true});
        }
      }).catch(function(error) {
        view.handleRequestError(error);
      }).then(function() {
        $form.find('[type=submit]').button('reset');
      });
  },

  formValues: function($form) {
    return _.reduce(
      $form.find(":input").serializeArray(),
      function(memo, i) { memo[i.name] = i.value; return memo; },
      {}
    );
  },

  formValidate: function(inst, $form) {
    return inst.isValid();
  },

  handleAction: function(eve) {
    eve.preventDefault();
    eve.stopPropagation();

    this.app.trigger('loadingStart');
    var $btn = $(eve.currentTarget),
        action = $btn.data('action');
    $btn.button('loading');
    this.hook(camelize('handle-' + action + '-action'), eve)
      .then(function() {
        $btn.button('reset');
      });
  },

  handleDeleteAction: function(eve) {
    var inst, view = this,
        $btn = $(eve.currentTarget),
        model_class = $btn.data('model'),
        model_id = $btn.data('model-id');

    if ( model_class && model_id ) {
      inst = new models[model_class]({id: model_id});
    } else {
      inst = this.model;
    }

    if(window.confirm('Are you sure you want to delete this?')) {
      return Promise.resolve( inst.destroy() )
        .then(function(response) {
            view.app.view.success( 'Deleted ' + model_class );
            if( _.isObject(view.model) ) {
              Backbone.history.navigate(
                view.model.urlRoot, {trigger: true} );
            } else {
              view.collection.remove( inst );
              return Promise.resolve( view.collection.fetch() );
            }
        }).catch(function(error) {
          view.handleRequestError(error);
        });
    }
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

  submitForm: function(eve) {
    $(eve.currentTarget).parents('form').submit();
  },

  handleFormChange: function(evt) {
    this.app.listener.pause();
    $('#viewBtn, #previewBtn, #deleteBtn, #publishBtn').attr('disabled', 'disabled');
  },

  _modelOrCollection: function() {
    if(_.isObject(this.collection)) { return this.collection; }
    else if(_.isObject(this.model)) { return this.model; }
  }
});

