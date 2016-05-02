"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('./models'),
    views = require('./views'),
    logger = require('./logger'),
    querystring = require('querystring');

module.exports = Backbone.Router.extend({

  initialize: function(options) {
    this.app = options.app;
    logger.debug("Init router");

    this.on("route", this.everyRoute);
  },

  routes: {
    "": "listProjects",
    "blueprints": "listBlueprints",
    "blueprints/new": "newBlueprint",
    "blueprints/:slug": "editBlueprint",
    "blueprints/:slug/new_project": "newProject",
    "blueprints/:slug/edit": "editBlueprint",
    "projects": "listProjects",
    "projects/new": "chooseBlueprint",
    "projects/:slug": "editProject",
    "projects/:slug/edit": "editProject",
    "projects/:slug/duplicate": "duplicateProject",
    "themes": "listThemes",
    "themes/new": "newTheme",
    "themes/:slug": "editTheme",
    "themes/:slug/edit": "editTheme"
  },

  // This is called for every route
  everyRoute: function(route, params) {
    // logger.debug('route params', route, params);
    this.app.trigger( 'loadingStart' );
    // if(params[])
    this.app.analyticsEvent( 'pageview' );
    this.app.messages.start();
    if ( params ) {
      this.app.trigger('leavePage');
      logger.debug(route, params);
    } else {
      logger.debug(route);
    }
  },

  listBlueprints: function(params) {
    var blueprints = this.app.blueprints,
        app = this.app, query = {}, view;
    if(params) { query = querystring.parse(params); }

    Promise.resolve( blueprints.fetch({data: query}) ).then(function() {
      view = new views.ListBlueprints({
        collection: blueprints,
        query: _.pick(query, 'type', 'tag', 'status', 'search'),
        app: app
      });
      view.render();

      app.view
        .display( view )
        .setTab('blueprints');

    }).catch(function(jqXHR) {
      app.view.displayError(jqXHR.status, jqXHR.statusText, jqXHR.responseText);
    });
  },

  newBlueprint: function() {
    var blueprint = new models.Blueprint(),
        view = new views.EditBlueprint({ model: blueprint, app: this.app });

    view.render();

    this.app.view
      .display( view )
      .setTab('blueprints');

  },

  editBlueprint: function(slug) {
    var app = this.app, view,
        blueprint = new models.Blueprint({ id: slug });

    Promise.resolve( blueprint.fetch() ).then(function() {
      var view = new views.EditBlueprint({ model: blueprint, app: app });
      view.render();

      app.view
        .display( view )
        .setTab('blueprints');

    }).catch(function(jqXHR) {
      app.view.displayError(jqXHR.status, jqXHR.statusText, jqXHR.responseText);
    });
  },

  chooseBlueprint: function(params) {
    var blueprints = this.app.blueprints,
        app = this.app, query = {}, view;

    if(params) { query = querystring.parse(params); }
    query['status'] = 'ready';

    Promise.resolve( blueprints.fetch({data: query}) ).then(function() {
      view = new views.ChooseBlueprint({
        collection: blueprints, query: query, app: app });
      view.render();

      app.view
        .display( view )
        .setTab('projects');

    }).catch(function(jqXHR) {
      app.view.displayError(jqXHR.status, jqXHR.statusText, jqXHR.responseText);
    });
  },

  listProjects: function(params) {
    var projects = this.app.projects,
        app = this.app, query = {}, view, jqxhr;

    if(params) { query = querystring.parse(params); }

    if (query.page) {
      jqxhr = projects.getPage(parseInt(query.page), {data: query});
    } else {
      jqxhr = projects.getFirstPage({data: query});
    }

    Promise.resolve( jqxhr ).then(function() {
      view = new views.ListProjects({
        collection: projects,
        query: _.pick(query, 'status', 'pub_status', 'blueprint_title', 'type', 'theme', 'search'),
        app: app
      });

      view.render();
      app.view
        .display( view )
        .setTab('projects');

    }).catch(function(jqXHR) {
      app.view.displayError(jqXHR.status, jqXHR.statusText, jqXHR.responseText);
    });
  },

  newProject: function(slug) {
    var app = this.app, view, project,
        blueprint = new models.Blueprint({ id: slug });

    Promise.resolve( blueprint.fetch() ).then(function() {
      project = new models.Project({ blueprint: blueprint });
      view = new views.EditProject({ model: project, app: app });
      view.render();
      app.view
        .display( view )
        .setTab('projects');
    }).catch(function(jqXHR) {
      app.view.displayError(jqXHR.status, jqXHR.statusText, jqXHR.responseText);
    });
  },

  editProject: function(slug, params) {
    var project = new models.Project({ id: slug }),
        app = this.app, view, query = {};

    if(params) { query = querystring.parse(params); }

    Promise.resolve( project.fetch() ).then(function() {
      project.blueprint = new models.Blueprint({
        id: project.get('blueprint_id') });

      return project.blueprint.fetch();
    }).then(function() {
      view = new views.EditProject({
        model: project, app: app, query: query,
        disableForm: query.hasOwnProperty('disableform') });
      view.render();

      app.view
        .display( view )
        .setTab('projects');

    }).catch(function(jqXHR) {
      app.view.displayError(jqXHR.status, jqXHR.statusText, jqXHR.responseText);
    });
  },

  // editProjectPreview: function

  duplicateProject: function(slug) {
    var project = new models.Project({ id: slug }),
        app = this.app, view,
        new_project, old_attributes, new_attributes = {};

    Promise.resolve( project.fetch() ).then(function() {
      project.blueprint = new models.Blueprint({
        id: project.get('blueprint_id') });
      return project.blueprint.fetch();
    }).then(function() {
      old_attributes = _.clone(project.attributes);
      logger.debug('oldies', old_attributes);
      new_attributes.blueprint_config = old_attributes.blueprint_config;
      new_attributes.blueprint_id = old_attributes.blueprint_id;
      new_attributes.blueprint_title = old_attributes.blueprint_title;
      new_attributes.blueprint_version = old_attributes.blueprint_version;
      new_attributes.data = old_attributes.data;
      new_attributes.theme = old_attributes.theme;
      new_attributes.title = 'Copy of ' + old_attributes.title;
      new_attributes.type = old_attributes.type;
      new_attributes.status = 'new';

      new_project = new models.Project(new_attributes);
      new_project.blueprint = project.blueprint;

      view = new views.EditProject({
        model: new_project, app: app, copyProject: true });
      view.render();

      app.view
        .display( view )
        .setTab('projects');
    }).catch(function(jqXHR) {
      app.view.displayError(jqXHR.status, jqXHR.statusText, jqXHR.responseText);
    });
  },

  listThemes: function(params) {
    var themes = this.app.editableThemes,
        app = this.app, query = {}, view, jqxhr;

    if(params) { query = querystring.parse(params); }

    if (query.page) {
      jqxhr = themes.getPage(parseInt(query.page), {data: query});
    } else {
      jqxhr = themes.getFirstPage({data: query});
    }

    Promise.resolve( jqxhr  ).then(function() {
      view = new views.ListThemes({
        collection: themes,
        query: _.pick(query, 'status', 'group', 'search'),
        app: app
      });
      view.render();

      app.view
        .display( view )
        .setTab('themes');

    }).catch(function(jqXHR) {
      app.view.displayError(jqXHR.status, jqXHR.statusText, jqXHR.responseText);
    });
  },

  editTheme: function(slug) {
    var app = this.app, view,
        theme = new models.Theme({ id: slug });

    Promise.resolve( theme.fetch() ).then(function() {
      var view = new views.EditTheme({ model: theme, app: app });
      view.render();

      app.view
        .display( view )
        .setTab('themes');

    }).catch(function(jqXHR) {
      app.view.displayError(jqXHR.status, jqXHR.statusText, jqXHR.responseText);
    });
  },

  newTheme: function() {
    var theme = new models.Theme(),
        view = new views.EditTheme({ model: theme, app: this.app });

    view.render();

    this.app.view
      .display( view )
      .setTab('themes');

  },
});
