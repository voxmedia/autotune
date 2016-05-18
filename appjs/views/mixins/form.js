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
    var $form;

    eve.preventDefault();
    eve.stopPropagation();

    logger.debug(eve);

    if ( eve.currentTarget.tagName === 'FORM' ) {
      $form = $(eve.currentTarget);
    } else {
      $form = $(eve.currentTarget).parents('form');
    }

    return this.doSubmit($form);
  },

  doSubmit: function(formEle) {
    logger.debug(formEle, this);
    var inst, Model, view = this, app = this.app,
        $form = this.$(formEle);
        logger.debug('22222', view, this);

    app.trigger('loadingStart');
    logger.debug('handleForm');

    var values = view.formValues($form),
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
      app.router.navigate(
        basepath + '?' + $form.serialize(),
        {trigger: true});
      return;
    } else { throw "Don't know how to handle this form"; }

    return this.hook('beforeSubmit', $form, values, action, inst)
      .then(function() {
        logger.debug('saving values', values);
        inst.set(values);
        if(!view.formValidate(inst, $form)) {
          logger.debug('form is not valid');
          throw 'Form is not valid';
        }

        logger.debug('form is valid, saving...');

        return inst.save();
      }).then(function() {
        logger.debug('form finished saving');

        if ( action === 'new' ) {
          app.view.success('New '+model_class+' saved');
        } else {
          app.view.success(model_class+' updates saved');
        }

        return view.hook('afterSubmit');
      }).then(function() {
        logger.debug('next: '+next);
        if ( next === 'show' && action === 'new' ) {
          var updatedFormData = inst.formData();
          delete updatedFormData['slug'];
          view.formDataOnLoad = updatedFormData;
          app.router.navigate(inst.url(), {trigger: true});
        } else if ( next === 'show' ) {
          view.render();
        } else if ( next ) {
          app.router.navigate(next, {trigger: true});
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

  formValidate: function(inst, $form) {
    return inst.isValid();
  },

  submitForm: function(eve) {
    $(eve.currentTarget).parents('form').submit();
  }
};
