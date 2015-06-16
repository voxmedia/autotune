"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('../models'),
    logger = require('../logger'),
    camelize = require('underscore.string/camelize'),
    alert_template = require('../templates/alert.ejs'),
    BaseView = require('./BaseView');

module.exports = BaseView.extend({
  events: {
    'click a[href]': 'handleLink',
    'submit form': 'handleForm',
    'click button[data-action],a[data-action]': 'handleAction',
    'change select[data-auto-submit=true]': 'submitForm',
    'change :input': 'pauseListener'
  },

  initialize: function(options) {
    BaseView.prototype.initialize.call(this, options);
  },

  handleForm: function(eve) {
    eve.preventDefault();
    eve.stopPropagation();

    this.app.view.spinStart();
    logger.debug('handleForm');

    var inst, Model,
        $form = $(eve.currentTarget),
        values = this.formValues($form),
        model_class = $form.data('model'),
        model_id = $form.data('model-id'),
        action = $form.data('action'),
        next = $form.data('next');

    $form.find('[type=submit]').button('loading');

    if(model_class && action === 'new') {
      Model = models[model_class];
      this.hook('beforeSubmit', $form, values, action, Model);
      inst = new Model();
    } else if(_.isObject(this.model) && action === 'edit') {
      this.hook('beforeSubmit', $form, values, action, this.model);
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

    inst.set(values);
    if(!this.formValidate(inst, $form)) {
      $form.find('[type=submit]').button('reset');
      logger.debug('form is not valid');
      return false;
    }

    logger.debug('form is valid, saving...');

    inst.save()
      .done(_.bind(function() {
        $form.find('[type=submit]').button('reset');
        logger.debug('form finished saving');
        if(action === 'new') {
          this.app.view.success('New '+model_class+' saved');
        } else {
          this.app.view.success(model_class+' updates saved');
        }
        if(next === 'show') {
          Backbone.history.navigate(this.model.url(), {trigger: true});
        } else if(next){
          Backbone.history.navigate(next, {trigger: true});
        } else {
          if(_.isObject(this.collection)) {
            this.collection.fetch();
          } else if(_.isObject(this.model)) {
            this.model.fetch();
          }
        }
      }, this))
      .fail(_.bind(this.handleRequestError, this));
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
    this.app.view.spinStart();
    var $btn = $(eve.currentTarget),
        action = $btn.data('action');
    $btn.button('loading');
    this.hook(camelize('handle-' + action + '-action'), eve);
  },

  handleDeleteAction: function(eve) {
    var inst,
        $btn = $(eve.currentTarget),
        model_class = $btn.data('model'),
        model_id = $btn.data('model-id'),
        next = $btn.data('next');

    if(window.confirm('Are you sure you want to delete this?')) {
      inst = new models[model_class]({id: model_id});
      inst.destroy()
        .done(_.bind(function() {
          this.app.view.success('Deleted '+model_class);
          if(_.isObject(this.model)) {
            Backbone.history.navigate(this.model.urlRoot, {trigger: true});
          } else {
            this.collection.fetch();
          }
        }, this))
        .fail(_.bind(this.handleRequestError, this));
    } else {
      $btn.button('reset');
    }
  },

  handleRequestError: function(xhr, status, error){
    if(error === 'Bad Request') {
      var data = $.parseJSON(xhr.responseText);
      this.app.view.error(data.error);
    } else {
      this.app.view.error('Something bad happened... Please reload and try again');
    }
    logger.error("REQUEST FAILED!!", xhr, status, error);
  },

  submitForm: function(eve) {
    $(eve.currentTarget).parents('form').submit();
  },

  pauseListener: function(evt) {
    this.app.listener.pause();
  },

  _modelOrCollection: function() {
    if(_.isObject(this.collection)) { return this.collection; }
    else if(_.isObject(this.model)) { return this.model; }
  }
});

