"use strict";

var Backbone = require('backbone'),
    $ = require('jquery'),
    _ = require('underscore'),
    moment = require('moment'),
    utils = require('../utils'),
    markdown = require('markdown').markdown;

var Project = Backbone.Model.extend({
  urlRoot: '/projects',

  /**
   * Constructor. Looks for `blueprint` or `blueprint_name` in the object passed in.
   * @param {object} args Arguments passed to the constructor
   **/
  initialize: function(args) {
    if(_.isObject(args)) {
      if(_.isObject(args.blueprint)) {
        this.blueprint = args.blueprint;
        // attributes are already set at this point, so we have to delete the blueprint object
        delete this.attributes.blueprint;
      } else if(!_.isUndefined(args.blueprint_name)) {
        this.blueprint = new exports.Blueprint({name: args.blueprint_name});
      }

      if(_.isObject(args.theme)) {
        this.theme = args.theme;
        delete this.attributes.theme;
      }
    }
  },

  /**
   * Get the AJAX endpoint for this project.
   * @returns {string}
   **/
  url: function() {
    if(this.isNew()) { return this.urlRoot; }
    if(this.has('slug') && !this.hasChanged('slug')) {
      return [this.urlRoot, this.get('slug')].join('/');
    } else {
      return [this.urlRoot, this.id].join('/');
    }
  },

  /**
   * Rebuild this project.
   * @returns {object} jqXHR object
   **/
  build: function() {
    this.set('status', 'building');
    return Backbone.ajax({
      dataType: 'json',
      type: 'GET',
      url: this.url() + '/build'
    });
  },

  /**
   * Rebuild and publish this project.
   * @returns {object} jqXHR object
   **/
  buildAndPublish: function() {
    this.set('status', 'building');
    return Backbone.ajax({
      dataType: 'json',
      type: 'GET',
      url: this.url() + '/build_and_publish'
    });
  },

  /**
   * Update this project.
   * @returns {object} jqXHR object
   **/
  updateSnapshot: function() {
    this.set('status', 'updating');
    return Backbone.ajax({
      dataType: 'json',
      type: 'GET',
      url: this.url() + '/update_snapshot'
    });
  },

  /**
   * Does the blueprint for this project have instructions?
   * @returns {boolean}
   **/
  hasInstructions: function() {
    if ( this.get('blueprint_config') && this.get('blueprint_config').instructions ) {
      return true;
    } else if ( this.blueprint && this.blueprint.get('config') &&
                this.blueprint.get('config').instructions ) {
      return true;
    }
    return false;
  },

  /**
   * Get the blueprint instructions in HTML format.
   * @returns {string} HTML-formatted instructions
   **/
  instructions: function() {
    if(this.hasInstructions()) {
      var instructions;
      if ( this.get('blueprint_config') ) {
        instructions = this.get('blueprint_config').instructions;
      } else {
        instructions = this.blueprint.get('config')['instructions'];
      }
      return markdown.toHTML(instructions);
    }
  },

  /**
   * Get the data that was passed to the blueprint build.
   * @returns {object} Blueprint build data
   **/
  buildData: function() {
    return _.extend({ 'base_url': this.baseUrl() }, this.formData());
  },

  /**
   * Get the preview or published URL of this project, whichever is more relevent.
   * @returns {string} Preview or publish url
   **/
  baseUrl: function() {
    if (this.isDraft() || this.hasUnpublishedUpdates()) {
      return this.get('preview_url');
    } else {
      return this.get('publish_url');
    }
  },

  /**
   * Get the data to populate the alpaca form.
   * @returns {object} Data for Alpaca
   **/
  formData: function() {
    return _.extend({
      'title': this.get('title'),
      'slug': this.get('slug'),
      'theme': this.get('theme')
    }, this.get('data'));
  },

  /**
   * Get the data to populate the alpaca form.
   * @returns {object} Data for Alpaca
   **/
  getErrorMsg: function() {
    if ( this.has('error_message') ) {
      var msg = this.get('error_message');
      var fmt = function(o) {
        if ( _.isArray(o) ) {
          return o.map(fmt).join(', ');
        } else if ( _.isObject(o) ) {
          return Object.keys(o).reduce(function(m, k) {
            var str = fmt(k) + ': ' + fmt(o[k]);
            if ( m.length > 0 ) { return m + ', ' + str; }
            else { return str; }
          }, '');
        } else {
          return o;
        }
      };

      return fmt(msg);
    }
  },

  /**
   * Get the blueprint config.
   * @returns {object} The blueprint config
   **/
  getConfig: function() {
    if ( this.has('blueprint_config') ) {
      return this.get('blueprint_config');
    } else if ( this.blueprint && this.blueprint.has('config') ) {
      return this.blueprint.get('config');
    } else {
      throw 'This blueprint does not have a form!';
    }
  },

  /**
   * Do we have a config?
   * @returns {boolean}
   **/
  hasConfig: function() {
    return this.has('blueprint_config') ||
      (this.blueprint && this.blueprint.has('config'));
  },

  /**
   * Get the alpaca form config.
   * @returns {object} Data for Alpaca form
   **/
  getFormConfig: function() {
    if ( this.hasConfig() ) {
      return this.getConfig().form;
    } else {
      return null;
    }
  },

  /**
   * Get the themes.
   * @returns {array} Theme models
   **/
  getThemes: function() {
    if ( this.hasConfig() ) {
      return this.getConfig().themes || ['generic'];
    } else {
      return ['generic'];
    }
  },

  /**
   * Does this project have any of these statuses?
   * @param {string} status Check for this status
   * @returns {boolean}
   **/
  hasStatus: function() {
    var iteratee = function(m, i) {
      return m || this.get( 'status' ) === i;
    };
    return _.reduce( arguments, _.bind(iteratee, this), false );
  },

  /**
   * Does this project have any of these types?
   * @param {string} status Check for this status
   * @returns {boolean}
   **/
  hasType: function() {
    var iteratee = function(m, i) {
      return m || this.get( 'type' ) === i;
    };
    return _.reduce( arguments, _.bind(iteratee, this), false );
  },

  /**
   * Has this project ever been built?
   * Used for displaying active preview tab on static projects
   * @returns {boolean}
   **/
  hasInitialBuild: function() {
    return !!this.get('output');
  },

  /**
   * Is this project a draft?
   * @returns {boolean}
   **/
  isDraft: function() {
    return ! this.isPublished();
  },

  /**
   * Has this project been published?
   * @returns {boolean}
   **/
  isPublished: function() {
    return !!this.get('published_at');
  },

  /**
   * Does this project have changes that have not been published?
   * @returns {boolean}
   **/
  hasUnpublishedUpdates: function() {
    return moment(this.get('data_updated_at')).isAfter(this.get('published_at'));
  },

  /**
   * Can this project be published?
   * @returns {boolean}
   **/
  isPublishable: function() {
    return this.isDraft() || this.hasUnpublishedUpdates();
  },

  /**
   * Format and return the publish time in the local timezone.
   * @returns {string} published time
   **/
  publishedTime: function(){
    if(this.isPublished()){
      var localTime = moment.utc(this.get('published_at')).toDate();
      return moment(localTime).format('MMM DD, YYYY - hh:mmA');
    }
  },

  /**
   * Return the version of the blueprint
   * @returns {string} commit hash
   **/
  getVersion: function() {
    return this.get('blueprint_version') || this.blueprint.get('version');
  },

  /**
   * Get the url of the preview.
   * @param {string} preferredProto - Return the url with this protocol (http, https) if possible
   * @param {string} path - include this path in the URL
   * @returns {string} url
   **/
  getPreviewUrl: function(preferredProto, path) {
    return utils.buildUrl(this.get('preview_url'), path, preferredProto);
  },

  getPreviewSize: function() {
    console.log(this.model);
    console.log('getting preview size', this);
  },

  createSpreadsheet: function() {
    var ss_key = this.blueprint.get('config')['spreadsheet_template'].match(/[-\w]{25,}/)[0],
        base_url = window.location.href;
    $.ajax({
      type: "POST",
      url: base_url + "/create_spreadsheet",
      data: JSON.stringify(ss_key),
      contentType: 'application/json',
      dataType: 'json'
    }).done(function( data ) {
      if($( "input[name='google_doc_url']" ).val().length > 0){
        var confirm = window.confirm('This will replace the spreadsheet link currenlty associated with this project. Click "OK" to confirm the replacement.');
        if(confirm){
          $( "input[name='google_doc_url']" ).val(data.google_doc_url);
        }
      } else {
        $( "input[name='google_doc_url']" ).val(data.google_doc_url);
      }
    }).fail(function(err) {
      console.log('There was an error authenticating your Google account.', err);
    });
  },

  /**
   * Get the url to the published project.
   * @param {string} preferredProto - Return the url with this protocol (http, https) if possible
   * @param {string} path - include this path in the URL
   * @returns {string} url
   **/
  getPublishUrl: function(preferredProto, path) {
    return utils.buildUrl(this.get('publish_url'), path, preferredProto);
  }
});

module.exports = Project;
