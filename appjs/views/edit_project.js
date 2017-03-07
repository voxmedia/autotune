"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('../models'),
    helpers = require('../helpers'),
    utils = require('../utils'),
    logger = require('../logger'),
    BaseView = require('./base_view'),
    ace = require('brace'),
    pym = require('pym.js'),
    slugify = require("underscore.string/slugify");

require('brace/mode/json');
require('brace/theme/textmate');

function pluckAttr(models, attribute) {
  return _.map(models, function(t) { return t.get(attribute); });
}

function isVisible(control) {
  return control.type !== 'hidden' && $(control.domEl).is(':visible');
}

var ProjectSaveModal = Backbone.View.extend({

    id: 'save-modal',
    className: 'modal show',
    template: require('../templates/modal.ejs'),

    events: {
      'hidden': 'teardown',
      'click #closeModal': 'closeModal',
      'click #dismiss': 'cancel',
      'click #save': 'submit',
      'click': 'closeModal',
      'click .new-google-doc': 'createDocument'
    },

    initialize: function(options) {
      _.bindAll(this, 'show', 'teardown', 'render', 'renderView');
      logger.debug('init options', options);
      if (_.isObject(options)) {
        _.extend(this, _.pick(options, 'app', 'parentView'));
      }
      this.render();
    },

    show: function() {
      this.$el.modal('show');
    },

    teardown: function() {
      this.$el.data('modal', null);
      this.remove();
    },

    render: function() {
      this.renderView(this.template);
      return this;
    },

    renderView: function(template) {
      this.$el.html(template());
      this.$el.modal({show:false}); // dont show modal on instantiation
    },

    cancel: function(){
      $('.project-save-warning').hide();
      this.trigger('cancel');
      this.teardown();
    },

    submit: function(){
      var self = this;
      this.parentView
        .doSubmit( this.parentView.$('#projectForm form') )
        .then(function() {
          self.trigger('submit');
          self.teardown();
        });
    },

    closeModal: function(eve){
      if($(eve.target).hasClass('modal-backdrop') || $(eve.target).is('#closeModal')){
        this.teardown();
        this.trigger('close');
      }
    },
 });

var EditProject = BaseView.extend(require('./mixins/actions'), require('./mixins/form'), {
  template: require('../templates/project.ejs'),
  forceUpdateDataFlag: false,
  previousData: null,
  events: {
    'change :input': 'stopListeningForChanges',
    'change form': 'pollChange',
    'keyup #shareText': 'getTwitterCount',
    'keypress': 'pollChange',
    'click #savePreview': 'savePreview',
    'click .resize': 'resizePreview',
    'click #saveBtn': 'handleForm',
    'click .new-google-doc': 'createDocument',
    'mousedown #split-bar': 'enableFormResize',
    'mouseup': 'disableFormResize',
    'mousemove': 'resizeForm'
  },

  afterInit: function(options) {
    var view = this;
    this.disableForm = options.disableForm ? true : false;
    this.copyProject = options.copyProject ? true : false;

    _.bindAll(this, 'onWindowResize');

    // autoselect embed code on focus
    this.$el.on('focus', 'textarea#embedText', function() { $(this).select(); } );

    this.on('load', function() {
      // Stop listening for changes during loading
      this.listenTo(this.app, 'loadingStart', this.stopListeningForChanges, this);
      this.listenTo(this.app, 'loadingStop', this.listenForChanges, this);

      if ( this.model.hasPreviewType('live') && this.model.getConfig().spreadsheet_template ) {
        // If we have a google spreadsheet, update preview on window focus
        this.listenTo(this.app, 'focus', this.focusPollChange, this);
      }

      // setup warning for closing before saving
      window.onbeforeunload = function(event) {
        if(view.hasUnsavedChanges()){
          return 'You have unsaved changes!';
        }
      };

      // window resize handler
      $(window).on('resize', this.onWindowResize);

      $('#navbar-save-container').show();
    }, this);

    this.on('unload', function() {
      // Remove listers, stop listening for messages
      this.stopListening(this.app);
      this.stopListeningForChanges();
      window.onbeforeunload = undefined;
      $(window).off('resize', this.onWindowResize);

      $('#navbar-save-container').hide();

      // Remove the pym parent object
      if ( this.pym ) { this.pym.remove(); }
    }, this);
  },

  onWindowResize: function() {
    this.showPreviewButtons();
    if(this.formWidth){
      if($(window).width() > 768){
        $('#form-pane').css("width", this.formWidth);
        $('#preview-pane').css("width", $(window).width() - this.formWidth);
      } else {
        $('#form-pane').css("width", '100%');
        $('#preview-pane').css("width", '100%');
      }
    }
  },

  askToSave: function() {
    var view = this;
    var saveModal = new ProjectSaveModal({app: this.app, parentView: this}),
        ret = new Promise(function(resolve, reject) {
          saveModal.once('cancel submit', function() {
            resolve(true);
          });
          saveModal.on('close', function() {
            resolve(false);
          });
        });

    if($('#save-modal').length === 0){
      saveModal.show();
    }

    return ret;
  },

  enableFormResize: function(event){
    this.enableFormSlide = true;
  },

  disableFormResize: function(event){
    if(this.enableFormSlide){
      $('#embed-preview').removeClass('screen');
      this.enableFormSlide = false;
    }
  },

  resizeForm: function(event){
    var view = this;
    if(view.enableFormSlide){
      if($(window).width() > 768){
        $('#embed-preview').addClass('screen');
        if(event.pageX > 320 && $(window).width() - event.pageX > 300){
          view.formWidth = $(window).width() - event.pageX;
          $('#form-pane').css("width", view.formWidth);
          $('#preview-pane').css("width", event.pageX);
          view.showPreviewButtons();
        }
      }
    }
  },

  showPreviewButtons: function(){
    $('.nav-pills button').show();
    if($('#preview-pane').width() > 700){
      $('.nav-pills #fluid-view').trigger('click');
    } else if($('#preview-pane').width() > 400 && $('#preview-pane').width() < 701){
      $('.nav-pills #fluid-view').trigger('click');
      $('.nav-pills #medium-view').hide();
    } else {
      $('.nav-pills .resize#small-view').trigger('click');
      $('.nav-pills button').hide();
      if($(window).width() > 768){
        $('.nav-pills .resize#small-view').show();
      }
    }
    $('.nav-pills li button').show();
  },

  hasUnsavedChanges: function(){
    var view = this, data;

    if ( view.alpaca ) {
      data = view.alpaca.getValue();

      if(_.isEqual(view.formDataOnLoad, data) ){
        return false;
      } else {
        return true;
      }
    }
    return false;
  },

  focusPollChange: function(){
    this.forceUpdateDataFlag = true;
    this.pollChange();
  },

  pollChange: _.debounce(function(){
    var view = this,
        $form = this.$('#projectForm'),
        query = '',
        tweetTextControl = this.alpaca.childrenByPropertyId["tweet_text"],
        data = this.alpaca.getValue();

    if ( tweetTextControl ) {
      tweetTextControl.setValue($('textarea#shareText').val());
    }

    if ( view.postedPreviewData ) {
      data = view.postedPreviewData;
    }

    if ( this.hasUnsavedChanges() ) {
      $('.project-save-warning').show().css('display', 'inline-block');
      $('.project-saved').hide();
    } else {
      $('.project-save-warning').hide();
      $('.project-saved').show().css('display', 'inline-block');
    }

    // Don't do live preview stuff if this is not live previewable
    if ( !this.model.hasPreviewType('live') ) { return; }

    // Make sure the form is valid before proceeding
    // Alpaca takes a loooong time to validate a complex form
    if ( !this.formValidate(this.model, $form) ) {
      // If the form isn't valid, bail
      return;
    } else {
      if( this.forceUpdateDataFlag ){
        // Check the flag in case we want to force an update
        query = '?force_update=true';
        this.forceUpdateDataFlag = false;
      } else if ( _.isEqual( this.previousData, data ) && !$('#embed-preview').hasClass('loading') ) {
        // If data hasn't changed, bail
        return;
      }

      logger.debug('pollchange');

      // stash data so we can see if it changed
      this.previousData = data;

      // Now that data is connected and valid, show some sort of loading indicator:
      if ( $('#embed-preview.validation-error') ) {
        $('#embed-preview').removeClass('validation-error').addClass('loading');
      }

      return $.ajax({
        type: "POST",
        url: this.model.url() + "/build_data" + query,
        data: JSON.stringify(data),
        contentType: 'application/json',
        dataType: 'json'
      }).then(function( data ) {
        logger.debug('Updating live preview...');
        var iframeLoaded = _.once(function() {
          view.pym.sendMessage('updateData', JSON.stringify(data));
          $('#embed-preview').removeClass('loading');
        });

        if ( data.theme !== view.theme || !view.pym ) {
          if ( typeof data.theme !== 'undefined' ) {
            view.theme = data.theme;
            view.getTwitterCount();
          }
          var version = view.model.getVersion(),
            previewSlug = view.model.isThemeable() ?
                version :[version, view.theme].join('-'),
            previewUrl = view.model.blueprint.getMediaUrl( previewSlug + '/preview');

          if ( view.pym ) { view.pym.remove(); }
          view.pym = new pym.Parent('embed-preview', previewUrl);
          view.pym.iframe.onload = iframeLoaded;

          // In case some dumb script hangs the loading process
          setTimeout(iframeLoaded, 20000);
        } else {
          iframeLoaded();
        }
      }, function(err) {
        if ( err.status < 500 ) {
          view.app.view.error(
            "Can't update live preview (" +err.responseJSON.error+").", 'permanent');
        } else {
          view.app.view.error(
            "Could not update live preview, please contact support.", 'permanent' );
          logger.error(err);
        }
      });
    }
  }, 500),

  getTwitterCount: function(){
    var view = this;
    var getTwitterHandleLength = function(slug){
     return view.twitterHandles[slug] ? view.twitterHandles[slug].length : 0;
    };

    if ( view.model.hasBuildData() && $('textarea#shareText').length ) {
      var maxLen = 140 - ( 26 + getTwitterHandleLength(view.theme)),
          currentVal = maxLen - $('textarea#shareText').val().length;

      $('#tweetChars').html(currentVal);
      if(currentVal < 1){
        $('#tweetChars').addClass('text-danger');
      } else {
        $('#tweetChars').removeClass('text-danger');
      }
    }
  },

  savePreview: function(){
    this.$('#projectForm form').submit();
  },

  resizePreview: function(eve) {
    var $btn = $(eve.currentTarget);

    $btn
      .addClass('active')
      .siblings().removeClass('active');

    $('.preview-frame')
      .removeClass()
      .addClass('preview-frame ' + $btn.attr('id'));
  },

  listenForChanges: function() {
    logger.debug('start listening for changes:', !this.listening);
    if ( !this.model.isNew() && !this.listening ) {
      logger.debug('start listening for changes');
      this.listenTo(this.app.messages,
                    'change:project:' + this.model.id,
                    this.updateStatus, this);
      this.listening = true;
    }
  },

  stopListeningForChanges: function() {
    logger.debug('stop listening for changes');
    this.stopListening(this.app.messages);
    this.listening = false;
  },

  updateStatus: function(status) {
    logger.debug('Update project status: ' + status);
    if (status === 'built'){
      if(!this.model.hasPreviewType('live')){
        $('#embed-preview').removeClass('loading');
      }
      this.app.view.success('Building complete');
    }

    // fetch the model, re-render the view and catch errors
    var view = this;
    Promise
      .resolve(this.model.fetch())
      .then(function() {
        return view.render();
      }).catch(function(jqXHR) {
        view.parentView.displayError(
          jqXHR.status, jqXHR.statusText, jqXHR.responseText);
      });
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
    $('.project-save-warning').hide();
    this.stopListeningForChanges();
  },

  beforeSubmit: function() {
    this.stopListeningForChanges();
  },

  afterRender: function() {
    logger.debug('in after render');
    var view = this;

    view.enableFormSlide = false;
    view.showPreviewButtons();

    // Setup editor for data field
    if ( this.app.hasRole('superuser') ) {
      if ( !this.editor ) {
        this.editor = ace.edit('blueprint-data');
        this.editor.setShowPrintMargin(false);
        this.editor.setTheme("ace/theme/textmate");
        this.editor.setWrapBehavioursEnabled(true);

        var session = this.editor.getSession();
        session.setMode("ace/mode/json");
        session.setUseWrapMode(true);

        this.editor.renderer.setHScrollBarAlwaysVisible(false);
      }
      this.editor.setValue(
        JSON.stringify( this.model.formData(), null, "  " ), -1 );
    }

    return new Promise(function(resolve, reject) {
        view.renderForm(resolve, reject);
      }).then(function() {
        view.renderPreview();
        view.getTwitterCount();
      }).catch(function(err) {
        console.error(err);
      }).then(function() {
        view.listenForChanges();
      });
  },

  afterSubmit: function() {
    this.listenForChanges();
    if (this.model.hasStatus('building')){
      if(!this.model.hasPreviewType('live')){
        $('#embed-preview').addClass('loading');
      }
      this.app.view.alert(
        'Building... This might take a moment.', 'notice', 16000);
    }
  },

  renderPreview: function() {
    var formData = this.alpaca.getValue(),
      buildData = this.model.buildData(),
      previewUrl = '', iframeLoaded,
      previewSlug = '';

    // Preview is already rendered
    if ( this.pym && this.pym.iframe.parentElement ) { return; }

    this.$('#shareText').val(formData['tweet_text']);
    this.formDataOnLoad = formData;

    // Callback for when iframe loads
    var view = this;
    iframeLoaded = _.once(function() {
      logger.debug('iframeLoaded');
      if ( view.model.hasPreviewType('live') && view.model.hasBuildData() ) {
        view.pollChange();
      } else {
        if(!view.model.hasStatus('building')){
          $('#embed-preview').removeClass('loading');
        }
      }
    });

    // Figure out preview url
    if ( this.model.hasPreviewType('live') ) {
      // if the project has live preview enabled
      this.theme = this.model.get('theme') || formData['theme'] || 'custom';

      previewSlug = this.model.isThemeable() ? this.model.getVersion() :
        [this.model.getVersion(), this.theme].join('-');
      previewUrl = this.model.blueprint.getMediaUrl( previewSlug + '/preview');

    } else if ( this.model.hasType( 'graphic' ) && this.model.hasInitialBuild() ){
      // if the project is a graphic and has been built (but doesn't have live enabled)
      var previousPreviewUrl = this.model['_previousAttributes']['preview_url'];

      if ( previousPreviewUrl && previousPreviewUrl !== this.model.get('preview_url') ){
        previewUrl = previousPreviewUrl;
      } else {
        previewUrl = this.model.get('preview_url');
      }
    }

    if ( this.model.hasType( 'graphic' ) || this.model.hasPreviewType('live') ) {
      // Setup our iframe with pym
      if ( this.pym ) { this.pym.remove(); }
      if ( this.formValidate(this.model, this.$('#projectForm')) ){
        this.pym = new pym.Parent('embed-preview', previewUrl);
        this.pym.iframe.onload = iframeLoaded;
      }
      // In case some dumb script hangs the loading process
      setTimeout(iframeLoaded, 20000);
    }
  },

  renderForm: function(resolve, reject) {
    var $form = this.$('#projectForm'),
        view = this,
        form_config, availableThemes, populateForm = false;

    if ( this.disableForm ) {
      $form.append(
        '<div class="alert alert-warning" role="alert">Form is disabled</div>');
      return resolve();
    }

    // Alpaca form is already setup
    if ( $form.alpaca('get') ) { resolve(); }

    // Prevent return or enter from submitting the form
    $form.keypress(function(event){
      var field_type = event.originalEvent.srcElement.type;
      if (event.keyCode === 10 || event.keyCode === 13){
        if(field_type !== 'textarea'){
          event.preventDefault();
        }
      }
    });

    form_config = this.model.getConfig().form;

    if ( _.isUndefined(form_config) ) {
      this.app.view.error('This blueprint does not have a form!', true);
      return reject('This blueprint does not have a form!');
    }

    availableThemes = this.model.getConfig().themes ?
      _.filter(this.app.themes.models, _.bind(function(t) {
        return _.contains(this.model.getConfig().themes, t.get('slug'));
      }, this)) : this.app.themes.models;
    availableThemes = availableThemes || this.app.themes.where({slug : 'generic'});
    this.twitterHandles = _.object(this.app.themes.pluck('slug'), this.app.themes.pluck('twitter_handle'));

    var schema_properties = {
      "title": {
        "title": "Title",
        "type": "string",
        "required": true
      },
      "theme": {
        "title": "Theme",
        "type": "string",
        "required": true,
        "default": pluckAttr(availableThemes, 'slug')[0],
        "enum": pluckAttr(availableThemes, 'slug')
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
        "data-next": 'show',
        "method": 'post'
      }
    },
    options_fields = {
      "theme": {
        "type": "select",
        "optionLabels": _.map(availableThemes, function(t){
             if (t.get('title') === t.get('group_name')) {
               return t.get('group_name');
             }
             return t.get('group_name') + ' - ' + t.get('title');
           })
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
        "showMaxLengthIndicator": true,
        "fieldClass": "hidden"
      }
    };

    // if there is only one theme option, hide the dropdown

    // Temporarily disabling theme drop down hiding to fix custom color bug
    //if ( availableThemes.length === 1 ) {
    //  options_fields['theme']['fieldClass'] = 'hidden';
    //}

    // hide slug for blueprint types that are not apps
    if ( !_.contains(this.app.config.editable_slug_types, this.model.blueprint.get('type') ) ) {
      options_fields['slug']['fieldClass'] = 'hidden';
    }

    _.extend(schema_properties, form_config.schema.properties || {});
    if( form_config.options ) {
      _.extend(options_form, form_config.options.form || {});
      _.extend(options_fields, form_config.options.fields || {});
    }

    // This monkey-patches the config for google_doc_url fields to use the googledoc field control
    if ( options_fields.google_doc_url && options_fields.google_doc_url.type === 'url' ) {
      options_fields.google_doc_url.type = 'googledoc';
      if ( this.model.getConfig().spreadsheet_template ) {
        options_fields.google_doc_url.doc_template_url = this.model.getConfig().spreadsheet_template;
      }
    }

    var opts = {
      "schema": {
        "title": this.model.hasPreviewType('live') ? '' : this.model.getConfig().title,
        "description": this.model.getConfig().description,
        "type": "object",
        "properties": schema_properties
      },
      "options": {
        "form": options_form,
        "fields": options_fields,
        "focus": this.firstRender
      },
      "postRender": function(control) {
        view.alpaca = control;

        view.alpaca.childrenByPropertyId["slug"].setValue(
          view.model.get('slug_sans_theme') );

        resolve();
      }
    };

    if( form_config['view'] ) {
      opts.view = form_config.view;
    }

    if(!this.model.isNew() || this.copyProject) {
      populateForm = true;
    } else if (this.model.isNew() && !this.copyProject && !this.model.hasInitialBuild()){
      var uniqBuildVals = _.uniq(_.values(this.model.buildData()));
      if (!( uniqBuildVals.length === 1 && typeof(uniqBuildVals[0]) === 'undefined')){
        populateForm = true;
      }
    }

    if(populateForm){
      opts.data = this.model.formData();
      if ( !_.contains(pluckAttr(availableThemes, 'slug'), opts.data.theme) ) {
        opts.data.theme = pluckAttr(availableThemes, 'slug')[0];
      }
    }

    $form.alpaca(opts);
  },

  formValues: function($form) {
    var control = $form.alpaca('get'), data;

    logger.debug('form values');

    if ( control ) {
      // get data from alpaca
      data = control.getValue();
    } else {
      // get data from the developer editor
      try {
        data = JSON.parse(this.editor.getValue());
      } catch (ex) {
        return {};
      }
    }

    // If we're updating, only worry about title, theme, slug and data
    var vals = {
      title: data['title'],
      theme: data['theme'],
      data:  data
    };

    if ( this.model.isNew() ) {
      // If this is a new project, we need the blueprint id. If we're
      // duplicating a project, we need version and config too.
      _.extend(vals, {
        blueprint_id: this.model.getBlueprintAttr('id'),
        blueprint_version: this.model.getVersion(),
        blueprint_config: this.model.getConfig()
      });
    }

    // Set our slug to start with the theme, if it doesn't already
    if ( data.slug && data.slug.indexOf(data.theme) !== 0 ) {
      vals.slug = data.theme + '-' + data.slug;
    }

    return vals;
  },

  formValidate: function(inst, $form) {
    var control = $form.alpaca('get'), valid = false;

    logger.debug('form validate');

    if ( control ) {
      // Validate the alpaca form
      control.form.refreshValidationState(true);
      valid = control.form.isFormValid();

      if ( !valid ) {
        $form.find('#validation-error').removeClass('hidden');
      } else {
        $form.find('#resolve-message').removeClass('hidden');
        $form.find('#validation-error').addClass('hidden');
      }
    } else {
      // Validate the raw data editor
      try {
        JSON.parse(this.editor.getValue());
        valid = true;
      } catch (ex) {
        logger.error("Blueprint raw JSON is bad");
      }
    }
    return valid;
  },

  copyEmbedToClipboard: function() {
    // select text from
    this.$( '#embedText' ).select();
    try {
      // copy text
      document.execCommand( 'copy' );
      this.app.view.alert( 'Embed code copied to clipboard!' );
    } catch ( err ) {
      this.app.view.alert( 'Please press Ctrl/Cmd+C to copy the text.' );
    }
  },

  /**
   * Create a new spreadsheet from a template
   * @returns {Promise} Promise to provide the Google Doc URL
   **/
  createDocument: function(eve) {
    eve.preventDefault();
    eve.stopPropagation();

    var $btn = $(eve.currentTarget);

    var model = this.model, view = this;
    if ( !$btn.data('template-id') ) { return; }

    var ss_key = $btn.data('template-id');

    var ctrl = this.alpaca.childrenById[$btn.data('target')];
    if( ctrl.getValue().trim().length > 0 ) {
      var msg = 'This will replace the currently associated document. Click "OK" to confirm the replacement.';
      if ( !window.confirm(msg) ) { return; }
    }

    return Promise.resolve( $.ajax({
      type: "POST",
      url: model.urlRoot + "/create_google_doc",
      data: JSON.stringify({ google_doc_id: ss_key }),
      contentType: 'application/json',
      dataType: 'json'
    }) ).then(
      function( data ) {
        ctrl
          .setValue(data.google_doc_url)
          .refreshValidationState()
          .focus();
      },
      function(err) {
        var msg = 'There was an error authenticating your Google account.';
        view.app.view.error(msg);
        logger.error(msg, err);
      }
    );
  },

  isNewProject: function() {
    return this.model.isNew() || this.copyProject;
  }
} );

module.exports = EditProject;
