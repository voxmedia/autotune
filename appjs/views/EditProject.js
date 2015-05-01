"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('../models'),
    FormView = require('./FormView');

module.exports = FormView.extend({
  template: require('../templates/project_form.ejs'),
  afterRender: function() {
    var $form = this.$el.find('#projectForm'),
        form_config = this.model.blueprint.get('config').form;
    if(_.isUndefined(form_config)) {
      this.error('This blueprint does not have a form!');
    } else {
      var schema_properties = {
            "title": {
              "title": "Title",
              "description": "hello world?",
              "type": "string",
              "required": true
            },
            "slug": {
              "title": "Slug",
              "description": "hello world?",
              "type": "string"
            }
          },
          options_form = {
            "attributes": {
              "data-model": "Project",
              "data-model-id": this.model.isNew() ? '' : this.model.id,
              "data-action": this.model.isNew() ? 'new' : 'edit',
              "data-next": "show"
            },
            "buttons": { "submit": { "value": "Save" } }
          },
          options_fields = {};

      _.extend(schema_properties, form_config['schema']['properties'] || {});
      if(form_config['options']) {
        _.extend(options_form, form_config['options']['form'] || {});
        _.extend(options_fields, form_config['options']['fields'] || {});
      }

      var opts = {
        "schema": {
          "title": this.model.blueprint.get('title'),
          "description": this.model.blueprint.get('config').description,
          "type": "object",
          "properties": schema_properties
        },
        "options": {
          "form": options_form,
          "fields": options_fields
        }
      };
      if(!this.model.isNew()) {
        opts.data = {
          'title': this.model.get('title'),
          'slug': this.model.get('slug')
        };
        _.extend(opts.data, this.model.get('data'));
      }
      $form.alpaca(opts);
    }
  },
  formValues: function($form) {
    var data = $form.alpaca('get').getValue();
    return {
      title: data['title'],
      slug:  data['slug'],
      theme: data['theme'],
      data:  data,
      blueprint_id: this.model.blueprint.get('id')
    };
  }
});
