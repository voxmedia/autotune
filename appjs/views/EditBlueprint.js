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

var setup = function(formData) {
  var data = formData.data,
      schema = formData.schema,
      options = formData.options,
      editor, mainPreviewField;

  setSourceHeight();

  editor = ace.edit('schema');
  editor.setTheme("ace/theme/textmate");
  editor.getSession().setMode("ace/mode/javascript");
  editor.renderer.setHScrollBarAlwaysVisible(false);
  editor.setShowPrintMargin(false);
  editor.setValue( JSON.stringify( formData , null, "  " ), -1 );

  var updatePreview = function() {
    logger.debug('Updating preview');
    try {
      formData = JSON.parse(editor.getValue());
      schema = formData.schema;
      options = formData.options || {};
      data = formData.data;
    } catch (ex) {
      logger.error("Can't update preview, JSON is bad");
      return;
    }

    if (mainPreviewField) {
      data = mainPreviewField.getValue();
      mainPreviewField.destroy();
      mainPreviewField = null;
    }

    var config = {
      schema: schema,
      options: options,
      postRender: function(form) {
        logger.debug('post render');
        mainPreviewField = form;
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

    $('#previewDiv').alpaca(config);
  };

  var debouncedUpdatePreview = _.debounce(updatePreview, 500);

  editor.on("change", function() {
    logger.debug('editor content changed');
    debouncedUpdatePreview();
  });

  updatePreview();
};

var EditBlueprint = BaseView.extend(require('./mixins/actions'), require('./mixins/form'), {
  template: require('../templates/blueprint.ejs'),
  events: {
    'change :input': 'stopListeningForChanges'
  },

  afterInit: function() {
    this.listenForChanges();
  },

  listenForChanges: function() {
    if ( !this.model.isNew() ) {
      this.listenTo(this.app.listener,
                    'change:blueprint:' + this.model.id,
                    this.updateStatus, this);
    }
  },

  stopListeningForChanges: function() {
    this.stopListening(this.app.listener);
  },

  updateStatus: function(status) {
    logger.debug('Update blueprint status: ' + status);
    this.model.set('status', status);
    this.render();
  },

  beforeRender: function() {
    this.stopListeningForChanges();
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

    this.listenForChanges();
  }
} );

module.exports = EditBlueprint;
