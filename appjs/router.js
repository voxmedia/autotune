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
    "projects/:slug/duplicate": "duplicateProject"
  },

  // This is called for every route
  everyRoute: function(route, params) {
    $(window).scrollTop(0);
    this.app.trigger( 'loadingStart' );
    this.app.analyticsEvent( 'pageview' );
    this.app.listener.start();
    if ( params ) {
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
    this.app.view
      .display( view )
      .setTab('blueprints');

    view.render();
  },

  editBlueprint: function(slug) {
    var blueprint = this.app.blueprints.findWhere({ slug: slug }),
        maybeFetch = Promise.resolve(),
        app = this.app, view;

    if ( !blueprint ) {
      blueprint = new models.Blueprint({ id: slug });
      this.app.blueprints.add(blueprint);
      maybeFetch = Promise.resolve( blueprint.fetch() );
    }

    maybeFetch.then(function() {
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
      view = new views.ChooseBlueprint({ collection: blueprints, query: query, app: app });
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
        // bp_list = this.app.blueprints.pluck('id', 'title'),
        app = this.app, query = {}, view, jqxhr;

    if(params) { query = querystring.parse(params); }

    if (query.page) {
      jqxhr = projects.getPage(parseInt(query.page));
    } else {
      jqxhr = projects.getFirstPage();
    }

    Promise.resolve( projects.fetch({data: query}) ).then(function() {
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
    var blueprint = this.app.blueprints.findWhere({ slug: slug }),
        maybeFetch = Promise.resolve(),
        app = this.app, view, project;

    if ( !blueprint ) {
      blueprint = new models.Blueprint({ id: slug });
      this.app.blueprints.add(blueprint);
      maybeFetch = Promise.resolve( blueprint.fetch() );
    }

    maybeFetch.then(function() {
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

  editProject: function(slug) {
    var project = this.app.projects.findWhere({ slug: slug }),
        maybeFetch = Promise.resolve('some value'),
        app = this.app, view, blueprint;

    if ( !project ) {
      project = new models.Project({ id: slug });
      this.app.projects.add(project);
      maybeFetch = Promise.resolve( project.fetch() );
    }

    maybeFetch.then(function() {
      blueprint = app.blueprints.findWhere({ id: project.get('blueprint_id') });

      if ( !blueprint ) {
        blueprint = new models.Blueprint({ id: project.get('blueprint_id') });
        app.blueprints.add(blueprint);
        return blueprint.fetch();
      }
    }).then(function() {
      project.blueprint = blueprint;
      view = new views.EditProject({ model: project, app: app });
      view.render();
      app.view
        .display( view )
        .setTab('projects');
    }).catch(function(jqXHR) {
      app.view.displayError(jqXHR.status, jqXHR.statusText, jqXHR.responseText);
    });
  },

  duplicateProject: function(slug) {
    var project = this.app.projects.findWhere({ slug: slug }),
        maybeFetch = Promise.resolve('some value'),
        app = this.app, view, blueprint;

    if ( !project ) {
      project = new models.Project({ id: slug });
      this.app.projects.add(project);
      maybeFetch = Promise.resolve( project.fetch() );
    }

    maybeFetch.then(function() {
      blueprint = app.blueprints.findWhere({ id: project.get('blueprint_id') });

      if ( !blueprint ) {
        blueprint = new models.Blueprint({ id: project.get('blueprint_id') });
        app.blueprints.add(blueprint);
        return blueprint.fetch();
      }
    }).then(function() {
      project.blueprint = blueprint;
      view = new views.DuplicateProject({ model: project, app: app });
      view.render();
      app.view
        .display( view )
        .setTab('projects');
    }).catch(function(jqXHR) {
      app.view.displayError(jqXHR.status, jqXHR.statusText, jqXHR.responseText);
    });
  }
});
