"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('../models'),
    logger = require('../logger'),
    BaseView = require('./base_view'),
    Alpaca = require('../alpaca_patches'),
    ace = require('brace');

require('brace/mode/json');
require('brace/theme/textmate');

var FormBuilder = BaseView.extend({
  template: require('../templates/form_builder.ejs'),
  events: {
  },

  afterInit: function() {
    if ( this.model ) {
      if ( this.model.has('blueprint_config') ) {
        this.initialFormData = this.model.get('blueprint_config').form;
      } else {
        this.initialFormData = this.model.get('config').form;
      }
    } else {
      this.initialFormData = {
        "schema": {
          "title": "Form title",
          "description": "Form description",
          "type": "object",
          "properties": {
            "title": {
              "title": "Basic input",
              "type": "string",
              "required": true
            }
          }
        },
        "options": { "fields": { } }
      };
    }
  },

  afterRender: function() {
    this.setSourceHeight();

    var editor = this.editor = ace.edit('schema');

    editor.setOptions({
      useWrapMode: true,   // wrap text to view
      indentedSoftWrap: false,
      theme: 'ace/theme/textmate'
    });
    editor.getSession().setMode("ace/mode/json");
    editor.renderer.setHScrollBarAlwaysVisible(false);
    editor.setShowPrintMargin(false);
    editor.setValue( JSON.stringify( this.initialFormData , null, "  " ), -1 );

    var debouncedUpdatePreview = _.debounce(
      _.bind(this.updateFormPreview, this), 500);

    editor.on("change", function() {
      logger.debug('editor content changed');
      debouncedUpdatePreview();
    });

    this.updateFormPreview();

    if ( window !== window.parent ) {
      var onMessage = function(data) {
        editor.setValue( JSON.stringify( data , null, "  " ), -1 );
      };

      this.on('load', function() {
        window.addEventListener('message', onMessage, false);
      }, this);

      this.on('unload', function() {
        window.removeEventListener('message', onMessage);
      }, this);

      window.parent.pushMessage('ready');
    }
  },

  updateFormPreview: function() {
    logger.debug('Updating preview');
    var $previewDiv = this.$('#previewDiv'),
        formData, schema, options, data, rawData;
    try {
      rawData = this.editor.getValue().trim();
      if ( rawData.length > 0 ) {
        formData = JSON.parse(rawData);
        schema = formData.schema;
        options = formData.options || {};
        data = formData.data;
      }
    } catch (ex) {
      logger.error(ex);
      logger.error("Can't update preview, JSON is bad");
      return;
    }

    if ( $previewDiv.alpaca('exists') ) {
      $previewDiv.alpaca('destroy');
    }

    if ( rawData.length === 0 ) {
      $previewDiv.html('Enter something into the editor to see the form preview here');
      return;
    } else {
      $previewDiv.empty();
    }

    var config = {
      schema: schema,
      options: options,
      postRender: function(form) {
        logger.debug('post render');
        $('.message').empty();
      },
      error: function(err) {
        Alpaca.defaultErrorCallback(err);
        $('.message')
          .html('<div class="alert alert-danger" role="alert">' + err.message + '</div>');
        logger.error("Alpaca encountered an error while previewing form -> " + err.message);
      }
    };

    if (data) { config.data = data; }

    $previewDiv.alpaca(config);
  },

  setSourceHeight: function() {
    logger.log(this.$('#builder').parent().length > 0);
    if ( this.$('#builder').parent().length > 0 ) {
      var top = this.$('#builder').parent().offset().top,
          height = $('body').height() - this.$('#builder').parent().height(),
          bottom = height - top;

      logger.debug(top, height, bottom);

      this.$('#builder').height(
        $(window).height() - ( top + bottom )
      );
    }
  }
} );

module.exports = FormBuilder;
