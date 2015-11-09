"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('../models'),
    helpers = require('../helpers'),
    logger = require('../logger'),
    BaseView = require('./base_view'),
    ace = require('brace'),
    slugify = require("underscore.string/slugify");

require('brace/mode/javascript');
require('brace/mode/html');
require('brace/theme/textmate');
require('brace/theme/chrome');

function pluckAttr(models, attribute) {
  return _.map(models, function(t) { return t.get(attribute); });
}

var EditProject = BaseView.extend(require('./mixins/actions'), require('./mixins/form'), {
  template: require('../templates/project.ejs'),
  events: {
    'change :input': 'stopListeningForChanges'
  },

  afterInit: function(options) {
    this.copyProject = options.copyProject ? true : false;
    this.listenForChanges();
  },

  listenForChanges: function() {
    if ( !this.model.isNew() ) {
      this.listenTo(this.app.listener,
                    'change:project:' + this.model.id,
                    this.updateStatus, this);
    }
  },

  stopListeningForChanges: function() {
    this.stopListening(this.app.listener);
  },

  updateStatus: function(status) {
    logger.debug('Update project status: ' + status);
    this.model.set('status', status);
    this.render();
  },

  templateData: function() {
    return {
      model: this.model,
      collection: this.collection,
      app: this.app,
      query: this.query,
      copyProject: this.copyProject
    };
  },

  beforeRender: function() {
    this.stopListeningForChanges();
  },

  beforeSubmit: function() {
    this.stopListeningForChanges();
  },

  afterRender: function() {
    var view = this, promises = [];

    if ( this.app.hasRole('superuser') ) {
      this.editor = ace.edit('blueprint-data');
      this.editor.setShowPrintMargin(false);
      this.editor.setReadOnly(true);
      this.editor.setTheme("ace/theme/textmate");
      this.editor.setWrapBehavioursEnabled(true);

      var session = this.editor.getSession();
      session.setMode("ace/mode/javascript");
      session.setUseWrapMode(true);

      this.editor.renderer.setHScrollBarAlwaysVisible(false);

      this.editor.setValue( JSON.stringify( this.model.buildData(), null, "  " ), -1 );
    }

    if ( this.model.isPublished() && this.model.blueprint.get('type') === 'graphic' ) {
      var proto = window.location.protocol.replace( ':', '' ),
          prefix = this.model.getPublishUrl(proto),
          embedUrl = this.model.getPublishUrl(proto) + '/embed.txt';

      promises.push( Promise
        .resolve( $.get( embedUrl ) )
        .then( function(data) {
          data = data.replace( /(?:\r\n|\r|\n)/gm, '' );
          view.$( '#embed textarea' ).text( data );
          $.each(view.$( '#screenshots img' ), function(){
            $(this).attr( 'src', prefix + '/' + $(this).attr('path') );
            $(this).removeAttr( 'path' );
          });
        }).catch(function(error) {
          logger.error(error);
        })
      );
    }

    promises.push( new Promise( function(resolve, reject) {
      view.renderForm(resolve, reject);
    } ) );

    return Promise.all(promises)
      .then(function() {
        view.listenForChanges();
      });
  },

  afterSubmit: function() {
    this.listenForChanges();

    if (this.model.hasStatus('building')){
      this.app.view.alert(
        'Building... This might take a moment.', 'notice', false, 16000);
    }
  },

  renderForm: function(resolve, reject) {
    var $form = this.$('#projectForm'),
        button_tmpl = require('../templates/project_buttons.ejs'),
        form_config, config_themes, newProject;

    // Prevent return or enter from submitting the form
    $form.keypress(function(event){
      var field_type = event.originalEvent.srcElement.type;
      if (event.keyCode === 10 || event.keyCode === 13){
        if(field_type !== 'textarea'){
          event.preventDefault();
        }
      }
    });

    if ( this.model.isNew() && !this.copyProject ) {
      newProject = true;
      form_config = this.model.blueprint.get('config').form;
      config_themes = this.model.blueprint.get('config').themes || ['generic'];
    } else if (this.copyProject) {
      newProject = true;
      form_config = this.model.get('blueprint_config').form;
      config_themes = this.model.get('blueprint_config').themes || ['generic'];
    } else {
      newProject = false;
      form_config = this.model.get('blueprint_config').form;
      config_themes = this.model.get('blueprint_config').themes || ['generic'];
    }

    if(_.isUndefined(form_config)) {
      this.app.view.error('This blueprint does not have a form!');
      reject('This blueprint does not have a form!');
    } else {
      var themes = this.app.themes.filter(function(theme) {
            if ( _.isEqual(config_themes, ['generic']) ) {
              return true;
            } else {
              return _.contains(config_themes, theme.get('value'));
            }
          }),
          social_chars = {
            "sbnation": 8,
            "theverge": 5,
            "polygon": 7,
            "racked": 6,
            "eater": 5,
            "vox": 9,
            "custom": 0
          },
          schema_properties = {
            "title": {
              "title": "Title",
              "type": "string",
              "required": true
            },
            "theme": {
              "title": "Theme",
              "type": "string",
              "required": true,
              "default": pluckAttr(themes, 'value')[0],
              "enum": pluckAttr(themes, 'value')
            },
            "slug": {
              "title": "Slug",
              "type": "string"
            },
            "tweet_text":{
              "type": "string",
              "minLength": 0
            }
          },
          options_form = {
            "attributes": {
              "data-model": "Project",
              "data-model-id": this.model.isNew() ? '' : this.model.id,
              "data-action": this.model.isNew() ? 'new' : 'edit',
              "data-next": 'show'
            }
          },
          options_fields = {
            "theme": {
              "type": "select",
              "optionLabels": pluckAttr(themes, 'label'),
            },
            "slug": {
              "label": "Slug",
              "validator": function(callback){
                var slugPattern = /^[0-9a-z\-_]{0,60}$/;
                var slug = this.getValue();
                if ( slugPattern.test(slug) ){
                  callback({ "status": true });
                } else if (slugPattern.test(slug.substring(0,60))){
                  this.setValue(slug.substr(0,60));
                  callback({ "status": true });
                } else {
                  callback({
                    "status": false,
                    "message": "Must contain fewer than 60 numbers, lowercase letters, hyphens, and underscores."
                  });
                }
              }
            },
            "tweet_text":{
              "label": "Social share text",
              "constrainMaxLength": true,
              "constrainMinLength": true,
              "showMaxLengthIndicator": true
            }
          };

      // if there is only one theme option, hide the dropdown
      if ( themes.length === 1 ) {
        options_fields['theme']['type'] = 'hidden';
      }

      _.extend(schema_properties, form_config['schema']['properties'] || {});
      if( form_config['options'] ) {
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
          "fields": options_fields,
          "focus": this.firstRender
        },
        "postRender": _.bind(function(control) {
          this.alpaca = control;

          var theme = control.childrenByPropertyId["theme"],
             social = control.childrenByPropertyId["tweet_text"];

          social.schema.maxLength = 140-(26+social_chars[theme.getValue()]);
          social.updateMaxLengthIndicator();

          $(theme).on('change', function(){
            social.schema.maxLength = 140-(26+social_chars[theme.getValue()]);
            social.updateMaxLengthIndicator();
          });

          this.alpaca.childrenByPropertyId["slug"].setValue(
            this.model.get('slug_sans_theme') );

          control.form.form.append(
            helpers.render(button_tmpl, this.templateData()) );

          resolve();
        }, this)
      };

      if( form_config['view'] ) {
        opts.view = form_config.view;
      }

      if(!this.model.isNew() || this.copyProject) {
        opts.data = this.model.formData();
        if ( !_.contains(pluckAttr(themes, 'value'), opts.data.theme) ) {
          opts.data.theme = pluckAttr(themes, 'value')[0];
        }
      }
      $form.alpaca(opts);
    }
  },

  formValues: function($form) {
    var data = $form.alpaca('get').getValue();
    var vals = {
      title: data['title'],
      theme: data['theme'],
      data:  data,
      blueprint_id: this.model.blueprint.get('id')
    };

    if ( data.slug ) {
      vals.slug = data['theme'] + '-' + data['slug'];
    }

    return vals;
  },

  formValidate: function(inst, $form) {
    var control = $form.alpaca('get'),
        valid = control.form.isFormValid();
    if ( !valid ) {
      control.form.refreshValidationState(true);
      $form.find('#validation-error').removeClass('hidden');
    } else {
      $form.find('#resolve-message').removeClass('hidden');
      $form.find('#validation-error').addClass('hidden');
    }
    return valid;
  }
} );

module.exports = EditProject;
