"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('./models'),
    FormView = require('./views/FormView');

module.exports = {
  ListBlueprints: FormView.extend({
    template: require('./templates/blueprint_list.ejs'),
    handleUpdateAction: function(eve) {
      var $btn = $(eve.currentTarget),
          model_class = $btn.data('model'),
          model_id = $btn.data('model-id'),
          inst = new models[model_class]({id: model_id});

      Backbone.ajax({
        type: 'GET',
        url: inst.url() + '/update_repo'
      })
        .done(_.bind(function() {
          this.success('Updating blueprint repo');
          inst.fetch();
        }, this))
        .fail(_.bind(this.handleRequestError, this));
    }

  }),
  EditBlueprint: FormView.extend({
    template: require('./templates/blueprint_form.ejs')
  }),
  ShowBlueprint: FormView.extend({
    template: require('./templates/blueprint.ejs'),
    handleUpdateAction: function(eve) {
      var $btn = $(eve.currentTarget),
          model_class = $btn.data('model'),
          model_id = $btn.data('model-id'),
          inst = new models[model_class]({id: model_id});

      Backbone.ajax({
        type: 'GET',
        url: inst.url() + '/update_repo'
      })
        .done(_.bind(function() {
          this.success('Updating blueprint repo');
          inst.fetch();
        }, this))
        .fail(_.bind(this.handleRequestError, this));
    }
  }),
  ChooseBlueprint: FormView.extend({
    template: require('./templates/blueprint_chooser.ejs')
  }),
  ListProjects: FormView.extend({
    template: require('./templates/project_list.ejs')
  }),
  EditProject: FormView.extend({
    template: require('./templates/project_form.ejs'),
    afterRender: function() {
      var $form = this.$el.find('#projectForm'),
          form_config = this.model.blueprint.get('config').form;
      if(_.isUndefined(form_config)) {
        this.error('This blueprint does not have a form!');
      } else {
        var schema_properties = {
              "blueprint_id": { "type": "integer" },
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
                "data-action": this.model.isNew() ? 'new' : 'edit'
              },
              "buttons": { "submit": { "value": "Save" } }
            },
            options_fields = {
              "blueprint_id": { "type": "hidden" }
            };

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
        if(this.model.isNew()) {
          opts.data = {'blueprint_id': this.model.blueprint.get('id')};
        } else {
          opts.data = {
            'blueprint_id': this.model.blueprint.get('id'),
            'title': this.model.get('title'),
            'slug': this.model.get('slug')
          };
          _.extend(opts.data, this.model.get('data'));
        }
        console.log(opts);
        $form.alpaca(opts);
      }
    }
  }),
  ShowProject: FormView.extend({
    template: require('./templates/project.ejs')
  })
};
