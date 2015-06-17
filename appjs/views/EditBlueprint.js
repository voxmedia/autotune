"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('../models'),
    logger = require('../logger'),
    FormView = require('./FormView'),
    Alpaca = require('../vendor/alpaca'),
    ace = require('brace');

require('brace/mode/javascript');
require('brace/theme/textmate');

var setup = function(formData) {
  var data = formData.data,
      schema = formData.schema,
      options = formData.options;

  var prettyJSON = function(obj) {
    return JSON.stringify(obj , null, "  ");
  };

  var sourceRefresh = function(form) {
    console.log('form change');

    var config,
        cursor = editor1.getCursorPosition();
    try {
      config = JSON.parse(editor1.getValue());
    } catch (ex) {
      rtProcessing = false;
      return;
    }
    config.data = form.getValue();
    editor1.setValue(prettyJSON(config), -1);

    setTimeout(function() {
      console.log('cleanup');
      rtProcessing = rtChange = false;
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
    var top = $('#builder').parent().offset().top,
        height = $('body').height() - $('#builder').parent().height(),
        bottom = height - top;
    logger.debug(top, height, bottom);
    $('#builder').height(
      $(window).height() - ( top + bottom )
    );
  };

  setSourceHeight();
  var editor1 = setupEditor("schema", formData);
  $(window).resize(setSourceHeight);

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
          console.log(error);
          $('.message')
            .html('<div class="alert alert-danger" role="alert">' + error.message + '</div>');
          console.log("Alpaca encountered an error while previewing form -> " + error.message);
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

  var rtChange = false;
  editor1.on("change", function() {
    console.log('change');
    rtChange = true;
  });

  // background "thread" to detect changes and update the preview div
  var rtProcessing = false;
  var rtFunction = function() {
    if (rtChange && rtProcessing) {
      console.log('change blocked');
    } else if (rtProcessing) {
      console.log('process running');
    }
    if (rtChange && !rtProcessing) {
      console.log('rtProcessing');
      rtProcessing = true;

      try {
        JSON.parse(editor1.getValue());
      } catch (ex) {
        console.log('bad json');
        // editor content is bad. bail
        rtProcessing = rtChange = false;
        setTimeout(rtFunction, 1000);
        return;
      }

      if (mainPreviewField) {
        data = mainPreviewField.getValue();
        mainPreviewField.destroy();
        mainPreviewField = null;
      }
      doRefresh($("#previewDiv"), true, function(err, form) {
        rtChange = false;
        rtProcessing = false;
      });
    }

    setTimeout(rtFunction, 1000);
  };
  rtFunction();

  doRefresh($("#previewDiv"));
};

module.exports = FormView.extend({
  template: require('../templates/blueprint.ejs'),
  handleUpdateAction: function(eve) {
    var $btn = $(eve.currentTarget),
        model_class = $btn.data('model'),
        model_id = $btn.data('model-id'),
        inst = new models[model_class]({id: model_id});

    inst.updateRepo()
      .done(_.bind(function() {
        this.app.view.success('Updating blueprint repo');
        inst.fetch();
      }, this))
      .fail(_.bind(this.handleRequestError, this));
  },
  afterRender: function() {
    setup(this.model.get('config').form);

    console.log(Alpaca.getFieldClass('string'));
  }
});
