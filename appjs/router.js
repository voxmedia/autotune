"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('./models'),
    views = require('./views'),
    queryString = require('query-string');

module.exports = Backbone.Router.extend({

  initialize: function(options) {
    console.log("Init router");

    if(options['app']) { this.app = options.app; }

    this.appView = new views.Application({ app: this.app });

    $('body').empty().append(this.appView.$el);
  },

  routes: {
    "": "listProjects",
    "blueprints": "listBlueprints",
    "blueprints/new": "newBlueprint",
    "blueprints/:slug": "showBlueprint",
    "blueprints/:slug/new_project": "newProject",
    "blueprints/:slug/builder": "builderBlueprint",
    "blueprints/:slug/edit": "editBlueprint",
    "projects": "listProjects",
    "projects/new": "chooseBlueprint",
    "projects/:slug": "showProject",
    "projects/:slug/edit": "editProject"
  },

  listBlueprints: function(params) {
    console.log("listBlueprints", params);
    this.appView.spinStart();
    var blueprints = this.blueprints = new models.BlueprintCollection(),
        query = {};
    if(params) { query = queryString.parse(params); }
    blueprints.fetch({data: query})
      .always(_.bind(function() {
        this.appView.display( new views.ListBlueprints(
          {collection: blueprints, query: query, app: this.app}) );
        this.appView.setTab('blueprints');
        this.appView.spinStop();
      }, this));
  },

  newBlueprint: function() {
    console.log("newBlueprint");
    this.appView.setTab('blueprints');
    this.appView.display( new views.EditBlueprint({
      model: new models.Blueprint(), app: this.app }));
    this.appView.spinStop();
  },

  showBlueprint: function(slug) {
    console.log("showBlueprint");
    this.appView.spinStart();
    var blueprint = new models.Blueprint({id: slug});
    blueprint.fetch()
      .always(_.bind(function() {
        this.appView.display( new views.ShowBlueprint({ model: blueprint, app: this.app }) );
        this.appView.setTab('blueprints');
        this.appView.spinStop();
      }, this));
  },

  editBlueprint: function(slug) {
    console.log("editBlueprint");
    this.appView.spinStart();
    var blueprint = new models.Blueprint({id: slug});
    blueprint.fetch()
      .always(_.bind(function() {
        this.appView.display( new views.EditBlueprint({ model: blueprint, app: this.app }) );
        this.appView.setTab('blueprints');
        this.appView.spinStop();
      }, this));
  },

  chooseBlueprint: function(params) {
    console.log("chooseBlueprint");
    this.appView.spinStart();
    var blueprints = new models.BlueprintCollection(),
        query = {};
    if(params) { query = queryString.parse(params); }
    query['status'] = 'ready';
    blueprints.fetch({data: query})
      .always(_.bind(function() {
        this.appView.display( new views.ChooseBlueprint(
          { collection: blueprints, query: query, app: this.app }) );
        this.appView.setTab('projects');
        this.appView.spinStop();
      }, this));
  },

  listProjects: function(params) {
    console.log("listProjects");
    this.appView.spinStart();
    var projects = new models.ProjectCollection(),
        query = {};
    if(params) { query = queryString.parse(params); }
    projects.fetch({data: query})
      .always(_.bind(function() {
        this.appView.display( new views.ListProjects(
          { collection: projects, query: query, app: this.app }) );
        this.appView.setTab('projects');
        this.appView.spinStop();
      }, this));
  },

  newProject: function(slug) {
    console.log("newProject");
    this.appView.spinStart();
    var blueprint = new models.Blueprint({id: slug});
    blueprint.fetch()
      .always(_.bind(function() {
        this.appView.display( new views.EditProject(
          { model: new models.Project({ blueprint: blueprint, app: this.app }) }) );
        this.appView.setTab('projects');
        this.appView.spinStop();
      }, this));
  },

  showProject: function(slug) {
    console.log("showProject");
    this.appView.spinStart();
    var project = new models.Project({id: slug});
    project.fetch()
      .always(_.bind(function() {
        this.appView.display( new views.ShowProject({ model: project, app: this.app }) );
        this.appView.setTab('projects');
        this.appView.spinStop();
      }, this));
  },

  editProject: function( slug) {
    console.log("editProject");
    this.appView.spinStart();
    var project = new models.Project({id: slug});
    project.fetch()
      .always(_.bind(function() {
        project.blueprint = new models.Blueprint({id: project.get('blueprint_id')});
        project.blueprint.fetch()
          .always(_.bind(function() {
            this.appView.display( new views.EditProject({ model: project, app: this.app }) );
            this.appView.setTab('projects');
            this.appView.spinStop();
          }, this));
      }, this));
  }
});
