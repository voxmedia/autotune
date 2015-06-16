"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('./models'),
    views = require('./views'),
    logger = require('./logger'),
    queryString = require('query-string');

module.exports = Backbone.Router.extend({

  initialize: function(options) {
    this.app = options.app;
    logger.debug("Init router");

    this.on("route", this.everyRoute);

    this.app.view = this.app.view = new views.Application({ app: this.app });
    this.app.view.render();
    $('body').prepend(this.app.view.$el);
  },

  routes: {
    "": "listProjects",
    "blueprints": "listBlueprints",
    "blueprints/new": "newBlueprint",
    "blueprints/:slug": "showBlueprint",
    "blueprints/:slug/new_project": "newProject",
    "blueprints/:slug/builder": "blueprintBuilder",
    "blueprints/:slug/edit": "editBlueprint",
    "projects": "listProjects",
    "projects/new": "chooseBlueprint",
    "projects/:slug": "editProject",
    "projects/:slug/edit": "editProject"
  },

  // This is called for every route
  everyRoute: function(route, params) {
    this.app.view.spinStart();
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
        query = {}, view;
    if(params) { query = queryString.parse(params); }
    view = new views.ListBlueprints({ collection: blueprints, query: query, app: this.app });
    this.app.view
      .display( view )
      .setTab('blueprints');
    blueprints.fetch();
  },

  newBlueprint: function() {
    var blueprint = new models.Blueprint(),
        view = new views.EditBlueprint({ model: blueprint, app: this.app });
    this.app.view
      .display( view )
      .setTab('blueprints');
    view.render();
  },

  showBlueprint: function(slug) {
    var blueprint = this.app.blueprints.findWhere({ slug: slug }) ||
                      new models.Blueprint({ id: slug }),
        view = new views.ShowBlueprint({ model: blueprint, app: this.app });
    this.app.view
      .display( view )
      .setTab('blueprints');
    blueprint.fetch();
  },

  editBlueprint: function(slug) {
    var blueprint = this.app.blueprints.findWhere({ slug: slug }) ||
                      new models.Blueprint({ id: slug }),
        view = new views.EditBlueprint({ model: blueprint, app: this.app });
    this.app.view
      .display( view )
      .setTab('blueprints');
    blueprint.fetch();
  },

  chooseBlueprint: function(params) {
    var blueprints = this.app.blueprints,
        query = {}, view;
    if(params) { query = queryString.parse(params); }
    query['status'] = 'ready';
    view = new views.ChooseBlueprint({ collection: blueprints, query: query, app: this.app });
    this.app.view
      .display( view )
      .setTab('projects');
    blueprints.fetch();
  },

  blueprintBuilder: function(slug) {
    var blueprint = this.app.blueprints.findWhere({ slug: slug }) ||
                      new models.Blueprint({ id: slug }),
        view = new views.BlueprintBuilder({ model: blueprint, app: this.app });
    this.app.view
      .display( view )
      .setTab('blueprints');
    blueprint.fetch();
  },

  listProjects: function(params) {
    var projects = this.app.projects,
        query = {}, view;
    if(params) { query = queryString.parse(params); }
    view = new views.ListProjects({ collection: projects, query: query, app: this.app });
    this.app.view
      .display( view )
      .setTab('projects');
    projects.fetch();
  },

  newProject: function(slug) {
    var blueprint = this.app.blueprints.findWhere({ slug: slug }) ||
                      new models.Blueprint({ id: slug }),
        project = new models.Project({ blueprint: blueprint }),
        view = new views.EditProject({ model: project, app: this.app });
    this.app.view
      .display( view )
      .setTab('projects');
    blueprint.fetch();
  },

  editProject: function(slug) {
    var project = this.app.projects.findWhere({ slug: slug }) ||
                    new models.Project({ id: slug }),
        view = new views.EditProject({ model: project, app: this.app });
    this.app.view
      .display( view )
      .setTab('projects');
    project.fetch();
  }
});
