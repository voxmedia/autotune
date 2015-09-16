"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('../models'),
    logger = require('../logger'),
    BaseView = require('./BaseView'),
    Alpaca = require('../vendor/alpaca'),
    ace = require('brace');

require('brace/mode/javascript');
require('brace/mode/html');
require('brace/theme/textmate');
require('brace/theme/chrome');

var setup = function(formData) {
  var data = formData.data,
      schema = formData.schema,
      options = formData.options;

  var prettyJSON = function(obj) {
    return JSON.stringify(obj , null, "  ");
  };

  var sourceRefresh = function(form) {
    console.log("form", form);
    var config,
        cursor = editor1.getCursorPosition();
    try {
      config = JSON.parse(editor1.getValue());
    } catch (ex) {
      return;
    }
    config.data = form.getValue();
    editor1.setValue(prettyJSON(config), -1);

    setTimeout(function() {
      editor1.gotoLine(cursor.row, cursor.column);
    }, 50);
  };

  var setupEditor = function(id, json) {
    var text = "";
    if (json) { text = prettyJSON(json); }

    var editor = ace.edit(id);
    editor.setTheme("ace/theme/textmate");
    editor.getSession().setMode("ace/mode/javascript");
    editor.renderer.setHScrollBarAlwaysVisible(false);
    editor.setShowPrintMargin(false);
    editor.setValue(text, -1);

    return editor;
  };

  var setSourceHeight = function() {
    logger.log($('#builder').parent().length > 0);
    if ( $('#builder').parent().length > 0 ) {
      var top = $('#builder').parent().offset().top,
          height = $('body').height() - $('#builder').parent().height(),
          bottom = height - top;
      logger.debug(top, height, bottom);
      $('#builder').height(
        $(window).height() - ( top + bottom )
      );
    }
  };

  setSourceHeight();
  var editor1 = setupEditor("schema", formData);
  //$(window).resize(setSourceHeight);

  var mainViewField = null;
  var mainPreviewField = null;
  var mainDesignerField = null;

  var doRefresh = function(el, disableErrorHandling, cb) {
    try {
      formData = JSON.parse(editor1.getValue());
      schema = formData.schema;
      options = formData.options;
      data = formData.data;
    }
    catch (e) { }

    if (schema) {
      var config = { "schema": schema };
      if (options) { config.options = options; }
      if (data) { config.data = data; }
      if (!config.options) { config.options = {}; }

      config.options.focus = false;

      if ( cb ) {
        config.postRender = function(form) { cb(null, form); };
      }
      config.error = function(err) {
        Alpaca.defaultErrorCallback(err);
        cb(err);
      };

      if (disableErrorHandling) {
        Alpaca.defaultErrorCallback = function(error) {
          logger.error(error);
          $('.message')
            .html('<div class="alert alert-danger" role="alert">' + error.message + '</div>');
          logger.error("Alpaca encountered an error while previewing form -> " + error.message);
        };
      } else {
        Alpaca.defaultErrorCallback = Alpaca.DEFAULT_ERROR_CALLBACK;
      }
      $('.message').empty();
      $(el).alpaca(config);
    }
  };

  var refreshPreview = function(callback) {
    if (mainPreviewField) {
      mainPreviewField.destroy();
      mainPreviewField = null;
    }

    doRefresh($("#previewDiv"), false, function(err, form) {
      if (!err) {
        mainPreviewField = form;

        $("#previewDiv :input[name]").change(function() {
          sourceRefresh(form);
        });
      }

      if (callback) { callback(); }
    });
  };

  var refreshCode = function(callback) {
    var json = { "schema": schema };
    if (options) { json.options = options; }
    if (data) { json.data = data; }

    if (callback) { callback(); }
  };

  var updatePreview = function() {
    logger.debug('Updating preview');
    try {
      JSON.parse(editor1.getValue());
    } catch (ex) {
      logger.error("Can't update preview, JSON is bad");
      return;
    }

    if (mainPreviewField) {
      data = mainPreviewField.getValue();
      mainPreviewField.destroy();
      mainPreviewField = null;
    }
    doRefresh($("#previewDiv"), true);
  };

  var debouncedUpdatePreview = _.debounce(updatePreview, 500);

  editor1.on("change", function() {
    logger.debug('editor content changed');
    debouncedUpdatePreview();
  });

  updatePreview();
};

module.exports = BaseView.extend(require('./mixins/actions'), require('./mixins/form'), {
  template: require('../templates/blueprint.ejs'),

  afterInit: function() {
    this.listenTo(this.model, 'change', this.render);
  },

  afterRender: function() {
    var $form = this.$el.find('#new-blueprint');
    $($form).keypress(function(event){
      if (event.keyCode === 10 || event.keyCode === 13){
        event.preventDefault();
      }
    });
    if ( !this.model.isNew() ) {
      setup(this.model.get('config').form);
    }
  }
} );
