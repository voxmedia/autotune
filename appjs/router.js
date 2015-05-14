"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('./models'),
    views = require('./views'),
    queryString = require('query-string');

module.exports = Backbone.Router.extend({

  initialize: function(options) {
    this.app = options.app;
    this.app.debug("Init router");

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
    "projects/:slug": "showProject",
    "projects/:slug/edit": "editProject"
  },

  // This is called for every route
  everyRoute: function(route, params) {
    this.app.view.spinStart();
    this.app.analyticsEvent( 'pageview' );
    if ( params ) {
      this.app.debug(route, params);
    } else {
      this.app.debug(route);
    }
  },

  listBlueprints: function(params) {
    var blueprints = this.blueprints = new models.BlueprintCollection(),
        query = {}, view;
    if(params) { query = queryString.parse(params); }
    view = new views.ListBlueprints({collection: blueprints, query: query, app: this.app});
    this.app.view.display( view );
    this.app.view.setTab('blueprints');
    blueprints.fetch({data: query});
    this.app.setActiveData(blueprints,query);
  },

  newBlueprint: function() {
    var blueprint = new models.Blueprint(),
        view = new views.EditBlueprint({ model: blueprint, app: this.app });
    this.app.view.display( view );
    this.app.view.setTab('blueprints');
    view.render();
    this.app.setActiveData();
  },

  showBlueprint: function(slug) {
    this.app.view.spinStart();
    var blueprint = new models.Blueprint({id: slug}),
        view = new views.ShowBlueprint({ model: blueprint, app: this.app });
    this.app.view.display( view );
    this.app.view.setTab('blueprints');
    blueprint.fetch();
    this.app.setActiveData(blueprint);
  },

  editBlueprint: function(slug) {
    this.app.view.spinStart();
    var blueprint = new models.Blueprint({id: slug}),
        view = new views.EditBlueprint({ model: blueprint, app: this.app });
    this.app.view.display( view );
    this.app.view.setTab('blueprints');
    blueprint.fetch();
    this.app.setActiveData();
  },

  chooseBlueprint: function(params) {
    this.app.view.spinStart();
    var blueprints = new models.BlueprintCollection(),
        query = {}, view;
    if(params) { query = queryString.parse(params); }
    query['status'] = 'ready';
    view = new views.ChooseBlueprint({ collection: blueprints, query: query, app: this.app });
    this.app.view.display( view );
    this.app.view.setTab('projects');
    blueprints.fetch({data: query});
    this.app.setActiveData();
  },

  blueprintBuilder: function(slug) {
    this.app.view.spinStart();
    var blueprint = new models.Blueprint({id: slug}),
        view = new views.BlueprintBuilder({ model: blueprint, app: this.app });
    this.app.view.display( view );
    this.app.view.setTab('blueprints');
    blueprint.fetch();
    this.app.setActiveData();
  },

  listProjects: function(params) {
    this.app.view.spinStart();
    var projects = new models.ProjectCollection(),
        query = {}, view;
    if(params) { query = queryString.parse(params); }
    view = new views.ListProjects({ collection: projects, query: query, app: this.app });
    this.app.view.display( view );
    this.app.view.setTab('projects');
    projects.fetch({data: query});
    this.app.setActiveData(projects,query);
  },

  newProject: function(slug) {
    this.app.view.spinStart();
    var blueprint = new models.Blueprint({id: slug}),
        project = new models.Project({ blueprint: blueprint }),
        view = new views.EditProject({ model: project, app: this.app });
    this.app.view.display( view );
    this.app.view.setTab('projects');
    blueprint.fetch();
    this.app.setActiveData();
  },

  showProject: function(slug) {
    this.app.view.spinStart();
    var project = new models.Project({id: slug}),
        view = new views.ShowProject({ model: project, app: this.app });
    this.app.view.display( view );
    this.app.view.setTab('projects');
    project.fetch();
    this.app.setActiveData(project);
  },

  editProject: function(slug) {
    this.app.view.spinStart();
    var project = new models.Project({ id: slug }),
        view = new views.EditProject({ model: project, app: this.app });
    this.app.view.display( view );
    this.app.view.setTab('projects');
    project.fetch();
    this.app.setActiveData();
  }
});
