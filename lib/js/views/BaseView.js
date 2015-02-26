"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('../models');

module.exports = Backbone.View.extend({
  events: {
    'click a': 'handleLink',
    'submit form': 'handleForm',
    'click button[data-action=delete]': 'handleDelete'
  },

  initialize: function() {
    var args = Array.prototype.slice.call(arguments);
    this.hook('beforeInit', args);

    if(_.isObject(this.collection)) {
      this.collection
        .on("sync sort", this.render, this)
        .on("error", this.logError, this);
    }

    if(_.isObject(this.model)) {
      this.model
        .on("sync change", this.render, this)
        .on("error", this.logError, this);
    }

    this.render();

    this.hook('afterInit', args);
  },

  handleLink: function(eve) {
    eve.preventDefault();
    eve.stopPropagation();
    Backbone.history.navigate(
      $(eve.currentTarget).attr('href'),
      {trigger: true});
  },

  handleForm: function(eve) {
    eve.preventDefault();
    var inst, Model,
        fields = {},
        $form = $(eve.currentTarget),
        model_class = $form.data('model'),
        model_id = $form.data('model-id'),
        action = $form.data('action');

    if(model_class) {
      if(action === 'new') {
        Model = models[model_class];
        this.hook('beforeSubmit', $form, fields, action, Model);
        inst = new Model();
      } else { return this.render(); }
    } else if(_.isObject(this.model)) {
      if(action === 'edit') {
        this.hook('beforeSubmit', $form, fields, action, this.model);
        inst = this.model;
      } else { return this.render(); }
    } else { return this.render(); }

    inst.set(fields);
    if(!inst.isValid()) { return this.render(); }

    inst.save()
      .done(_.bind(function() {
        if(_.isObject(this.collection)) {
          this.collection.fetch();
        } else if(_.isObject(this.model)) {
          this.model.fetch();
        } else {
          this.render();
        }
      }, this))
      .fail(_.bind(function(promise, status, error){
        $form.parent('.modal').modal('close');
        console.log("SAVE FAILED!!");
        console.log(status, error);
        this.render();
      }, this));

    return this;
  },

  handleDelete: function(eve) {
    var inst,
        $btn = $(eve.currentTarget),
        model_class = $btn.data('model'),
        model_id = $btn.data('model-id');

    if(window.confirm('Are you sure you want to delete this?')) {
      inst = new models[model_class]({id: model_id});
      inst.destroy();
      this._modelOrCollection().fetch();
    }
  },

  render: function() {
    var obj = this._modelOrCollection();

    this.hook('beforeRender', obj);

    this.$el.html(this.template(obj));

    this.hook('afterRender', obj);

    return this;
  },

  logError: function(model_or_collection, resp, options) {
    console.log(arguments);
  },

  error: function(message) {
    this.alert(message, 'danger');
  },

  success: function(message) {
    this.alert(message, 'success');
  },

  alert: function(message) {
    var level = arguments[1] || 'info';
    $('#notice').html('<div class="alert alert-' + level + '" role="alert">' + message + '</div>');
  },

  hook: function() {
    var args = Array.prototype.slice.call(arguments),
        name = args.shift();
    if(_.isFunction(this[name])) { return this[name](args); }
    this.trigger(name, args);
  },

  _modelOrCollection: function() {
    if(_.isObject(this.collection)) { return this.collection; }
    else if(_.isObject(this.model)) { return this.model; }
  },

  //_formData: function(ele) {
    //_.each($form.find(":input").serializeArray(), function(i) { fields[i.name] = i.value; });
  //}
});

