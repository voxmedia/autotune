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
    'submit form': 'handleForm',
    'change select[data-auto-submit=true]': 'submitForm'
  },

  handleForm: function(eve) {
    var inst, Model, view = this, app = this.app, $form;

    eve.preventDefault();
    eve.stopPropagation();

    if ( eve.currentTarget.tagName === 'FORM' ) {
      $form = $(eve.currentTarget);
    } else {
      $form = $(eve.currentTarget).parents('form');
    }

    this.app.trigger('loadingStart');
    logger.debug('handleForm');

    var values = this.formValues($form),
        meta = this.formMeta($form);

    $form.find('[type=submit]').button('loading');

    if ( meta.redirectUrl ) {
      Backbone.history.navigate( meta.redirectUrl, {trigger: true} );
      return;
    }

    return this.hook('beforeSubmit', $form, values, meta.action, meta.inst)
      .then(function() {
        logger.debug('saving values', values);
        inst.set(values);
        if(!view.formValidate(meta.inst, $form)) {
          logger.debug('form is not valid');
          throw 'Form is not valid';
        }

        logger.debug('form is valid, saving...');

        return meta.inst.save();
      }).then(function() {
        logger.debug('form finished saving');

        if ( meta.action === 'new' ) {
          app.view.success('New '+meta.model_class+' saved');
        } else {
          app.view.success(meta.model_class+' updates saved');
        }

        return view.hook('afterSubmit');
      }).then(function() {
        logger.debug('next: '+meta.next);
        if ( meta.next === 'show' && meta.action === 'new' ) {
          Backbone.history.navigate( meta.inst.url(), {trigger: true});
        } else if ( meta.next === 'show' ) {
          view.render();
        } else if ( meta.next ) {
          Backbone.history.navigate(meta.next, {trigger: true});
        } else {
          view.render();
        }
      }).catch(function(error) {
        app.trigger('loadingStop');
        $form.find('[type=submit]').button('reset');

        if ( _.isString( error ) ) {
          app.view.error( error );
        } else {
          view.handleRequestError(error);
        }
      });
  },

  formValues: function($form) {
    return _.reduce(
      $form.find(":input").serializeArray(),
      function(memo, i) { memo[i.name] = i.value; return memo; },
      {}
    );
  },

  formMeta: function($form) {
    var meta = {
      model_class: $form.data('model'),
      model_id: $form.data('model-id'),
      action: $form.data('action'),
      next: $form.data('next')
    };

    if(meta.model_class && meta.action === 'new') {
      meta.inst = new models[meta.model_class]();
    } else if(_.isObject(this.model) && meta.action === 'edit') {
      meta.inst = this.model;
    } else if ($form.attr('method').toLowerCase() === 'get') {
      // if the method attr is `get` then we can navigate to that new
      // url and avoid any posting
      var base = $form.attr('action') || window.location.pathname;
      meta.redirectUrl = base + '?' + $form.serialize();
    } else { throw "Don't know how to handle this form"; }

    return meta;
  },

  formValidate: function(inst, $form) {
    return inst.isValid();
  },

  formHasChanged: function($form) {
    var meta = this.formMeta($form);

    if ( meta.redirectUrl !=

  },

  submitForm: function(eve) {
    $(eve.currentTarget).parents('form').submit();
  }
};
