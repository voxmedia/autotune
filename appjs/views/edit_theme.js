'use strict';

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('../models'),
    helpers = require('../helpers'),
    logger = require('../logger'),
    BaseView = require('./base_view'),
    ace = require('brace'),
    slugify = require('underscore.string/slugify');

require('brace/mode/json');
require('brace/theme/textmate');

var EditTheme = BaseView.extend(require('./mixins/actions'), require('./mixins/form'), {
  template: require('../templates/theme.ejs'),
  events: {
    'change :input': 'stopListeningForChanges'
  },

  afterInit: function() {
    this.on('load', function() {
      this.listenTo(this.app, 'loadingStart', this.stopListeningForChanges, this);
      this.listenTo(this.app, 'loadingStop', this.listenForChanges, this);
    }, this);

    this.on('unload', function() {
      this.stopListening(this.app);
      this.stopListeningForChanges();
    }, this);
  },

  listenForChanges: function() {
    if (!this.model.isNew() && !this.listening) {
      logger.debug('Start listening for changes');
      this.listenTo(this.app.listener,
                    'change:theme:' + this.model.id,
                    this.updateStatus, this);
      this.listening = true;
    }
  },

  stopListeningForChanges: function() {
    logger.debug('Stop listening for changes');
    this.stopListening(this.app.listener);
    this.listening = false;
  },

  updateStatus: function(status) {
    logger.debug('Update theme status: ' + status);
    this.model.set('status', status);
    this.render();
  },

  beforeRender: function() {
    this.stopListeningForChanges();
  },

  afterRender: function() {
    var view = this, promises = [];

    // Setup editor for data field
    this.editor = ace.edit('data');
    this.editor.setShowPrintMargin(false);
    this.editor.setTheme('ace/theme/textmate');
    this.editor.setWrapBehavioursEnabled(true);

    var session = this.editor.getSession();
    session.setMode('ace/mode/json');
    session.setUseWrapMode(true);

    this.editor.renderer.setHScrollBarAlwaysVisible(false);
    var editor_data = JSON.stringify(this.model.get('data'), null, '  ');
    this.editor.setValue(editor_data ? editor_data : '{}', -1);

    if(this.model.get('parent_data')){
      this.readonlyEditor = ace.edit('readonly-data');
      this.readonlyEditor.setShowPrintMargin(false);
      this.readonlyEditor.setTheme('ace/theme/textmate');
      this.readonlyEditor.setWrapBehavioursEnabled(true);
      this.readonlyEditor.setReadOnly(true);

      this.readonlyEditor.renderer.setHScrollBarAlwaysVisible(false);
      this.readonlyEditor.setValue(JSON.stringify(this.model.get('parent_data'), null, '  '));

      var readonlySession = this.readonlyEditor.getSession();
      readonlySession.setMode('ace/mode/json');
      readonlySession.setUseWrapMode(true);
    }

    // initialize color pickers
    $('.colorpicker').spectrum({
      showInput: true,
      preferredFormat: 'hex'
    });

    this.listenForChanges();
  },

  formValues: function($form) {
    var values = {},
    parent_data = this.model.isDefault() ? null : this.model.get('parent_data'),
    devMode = $form.attr('id') === 'theme-data';

    // Parse the mainform if the editor is in visual mode
    if(!devMode){
      values.data = {};
      _.each($form.serializeArray(), _.bind(function(val) {
        var subGroup = null,
         propName = null;
        if(val.name.startsWith('themedata-')){
          subGroup = val.name.match('themedata-([a-zA-Z0-9]*)-.*$')[1];
          propName = val.name.match('themedata-[a-zA-Z0-9]*-(.*$)')[1];

          // Discard if this property value is the same as the parent
          if(this.isThemeValueInherited(subGroup, propName, val.value)){
            return;
          }
          if(subGroup === 'root'){
            values.data[propName] = val.value;
          } else {
            if (!values.data[subGroup]) {
              values.data[subGroup] = {};
            }
            values.data[subGroup][propName] = val.value;
          }
        } else {
          values[val.name] = val.value;
        }
      }, this));
    } else { // Accept data as is in dev mode
      try {
        values.data = JSON.parse(this.editor.getValue());
      } catch (ex) {
        logger.error('Theme data JSON is bad');
        return {};
      }
    }
    return values;
  },

  formValidate: function(){
    var valid = false;
    try {
      JSON.parse(this.editor.getValue());
      valid = true;
    } catch (ex) {
      logger.error('Theme data JSON is bad');
    }
    return valid;
  },

  isThemeValueInherited: function(subGroup, propName, value){
    if (this.model.isDefault()){
      return false;
    }
    var parent_data = this.model.get ('parent_data');

    if(subGroup === 'root'){
      return parent_data && parent_data[propName] &&
        parent_data[propName] === value;
    }
    return parent_data && parent_data[subGroup] &&
      parent_data[subGroup][propName] &&
      parent_data[subGroup][propName] === value;
  }
});

module.exports = EditTheme;
