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
    'change select[data-auto-submit=true]': 'submitForm',
    'change :input': 'handleFormChange'
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
        logger.debug('saving values', values);
        inst.set(values);
        if(!view.formValidate(inst, $form)) {
          $form.find('[type=submit]').button('reset');
          logger.debug('form is not valid');
          throw 'Form is not valid';
        }

        logger.debug('form is valid, saving...');

        return inst.save();
      }).then(function(data) {
        logger.debug('form finished saving');

        if ( action === 'new' ) {
          view.app.view.alert('New '+model_class+' saved', 'success', false, 4000);
        } else {
          view.app.view.alert(model_class+' updates saved', 'success', false, 4000);
        }

        if ( next === 'show' ) {
          Backbone.history.navigate(view.model.url(), {trigger: true});
        } else if ( next ) {
          Backbone.history.navigate(next, {trigger: true});
        }

        if (view.model.hasStatus('building')){
          view.app.view.alert('Building... This might take a moment.', 'notice', false, 16000);
        }
      }).catch(function(error) {
        if ( _.isString( error ) ) {
          view.app.view.error( error );
        } else {
          view.handleRequestError(error);
        }
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

  submitForm: function(eve) {
    $(eve.currentTarget).parents('form').submit();
  },

  handleFormChange: function(evt) {
    this.app.listener.pause();
    $('#viewBtn, #previewBtn, #deleteBtn, #publishBtn').attr('disabled', 'disabled');
  }
};
