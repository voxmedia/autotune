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
    eve.stopPropagation();
    var inst, Model,
        $form = $(eve.currentTarget),
        fields = this._formData(eve.currentTarget),
        model_class = $form.data('model'),
        model_id = $form.data('model-id'),
        action = $form.data('action');

    if(model_class && action === 'new') {
      Model = models[model_class];
      this.hook('beforeSubmit', $form, fields, action, Model);
      inst = new Model();
    } else if(_.isObject(this.model) && action === 'edit') {
        this.hook('beforeSubmit', $form, fields, action, this.model);
        inst = this.model;
    } else { throw "Don't know how to handle this form"; }

    inst.set(fields);
    if(!inst.isValid()) { return this.render(); }

    inst.save()
      .done(_.bind(function() {
        if(_.isObject(this.collection)) {
          this.collection.fetch();
        } else if(_.isObject(this.model)) {
          this.model.fetch();
        }
      }, this))
      .fail(_.bind(function(xhr, status, error){
        if(error === 'Bad Request') {
          var data = $.parseJSON(xhr.responseText);
          $form
            .find('.alert-danger')
            .text(data.error)
            .show();
        } else {
          $form
            .find('.alert-danger')
            .text('Something bad happened... Please reload and try again')
            .show();
        }
        console.log("SAVE FAILED!!");
        console.log(xhr.responseText, status, error);
      }, this));

    this.success('New blueprint saved');
    Backbone.history.navigate(
      $(eve.currentTarget).data('next'),
      {trigger: true});
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
    $('#flash').html('<div class="alert alert-' + level + '" role="alert">' + message + '</div>');
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

  _formData: function(ele) {
    var fields = {};
    _.each(
      $(ele).find(":input").serializeArray(),
      function(i) { fields[i.name] = i.value; }
    );
    return fields;
  }
});

