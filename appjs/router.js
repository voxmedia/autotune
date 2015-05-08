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

    this.app.view = this.app.view = new views.Application({ app: this.app });
    this.app.view.render();

    $('body').empty().append(this.app.view.$el);

    this.app.dataToRefresh = null;
    
    var source = new EventSource('changemessages');

    source.addEventListener('change', function(e) {
       if(app.dataToRefresh){
          app.dataToRefresh.fetch();
      }
    }, false);
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

  listBlueprints: function(params) {
    this.app.debug("listBlueprints", params);
    this.app.view.spinStart();
    var blueprints = this.blueprints = new models.BlueprintCollection(),
        query = {}, view;
    if(params) { query = queryString.parse(params); }
    view = new views.ListBlueprints({collection: blueprints, query: query, app: this.app});
    this.app.view.display( view );
    this.app.view.setTab('blueprints');
    blueprints.fetch({data: query});
    this.app.dataToRefresh = blueprints;
  },

  newBlueprint: function() {
    this.app.debug("newBlueprint");
    var blueprint = new models.Blueprint(),
        view = new views.EditBlueprint({ model: blueprint, app: this.app });
    this.app.view.display( view );
    this.app.view.setTab('blueprints');
    view.render();
    this.app.dataToRefresh = null;
  },

  showBlueprint: function(slug) {
    this.app.debug("showBlueprint");
    this.app.view.spinStart();
    var blueprint = new models.Blueprint({id: slug}),
        view = new views.ShowBlueprint({ model: blueprint, app: this.app });
    this.app.view.display( view );
    this.app.view.setTab('blueprints');
    blueprint.fetch();
    this.app.dataToRefresh = blueprint;
  },

  editBlueprint: function(slug) {
    this.app.debug("editBlueprint");
    this.app.view.spinStart();
    var blueprint = new models.Blueprint({id: slug}),
        view = new views.EditBlueprint({ model: blueprint, app: this.app });
    this.app.view.display( view );
    this.app.view.setTab('blueprints');
    blueprint.fetch();
    this.app.dataToRefresh = null;
  },

  chooseBlueprint: function(params) {
    this.app.debug("chooseBlueprint");
    this.app.view.spinStart();
    var blueprints = new models.BlueprintCollection(),
        query = {}, view;
    if(params) { query = queryString.parse(params); }
    query['status'] = 'ready';
    view = new views.ChooseBlueprint({ collection: blueprints, query: query, app: this.app });
    this.app.view.display( view );
    this.app.view.setTab('projects');
    blueprints.fetch({data: query});
    this.app.dataToRefresh = null;
  },

  blueprintBuilder: function(slug) {
    this.app.debug("blueprintBuilder");
    this.app.view.spinStart();
    var blueprint = new models.Blueprint({id: slug}),
        view = new views.BlueprintBuilder({ model: blueprint, app: this.app });
    this.app.view.display( view );
    this.app.view.setTab('blueprints');
    blueprint.fetch();
    this.app.dataToRefresh = null;
  },

  listProjects: function(params) {
    this.app.debug("listProjects");
    this.app.view.spinStart();
    var projects = new models.ProjectCollection(),
        query = {}, view;
    if(params) { query = queryString.parse(params); }
    view = new views.ListProjects({ collection: projects, query: query, app: this.app });
    this.app.view.display( view );
    this.app.view.setTab('projects');
    projects.fetch({data: query});
    this.app.dataToRefresh = projects;
  },

  newProject: function(slug) {
    this.app.debug("newProject");
    this.app.view.spinStart();
    var blueprint = new models.Blueprint({id: slug}),
        project = new models.Project({ blueprint: blueprint }),
        view = new views.EditProject({ model: project, app: this.app });
    this.app.view.display( view );
    this.app.view.setTab('projects');
    blueprint.fetch();
    this.app.dataToRefresh = null;
  },

  showProject: function(slug) {
    this.app.debug("showProject");
    this.app.view.spinStart();
    var project = new models.Project({id: slug}),
        view = new views.ShowProject({ model: project, app: this.app });
    this.app.view.display( view );
    this.app.view.setTab('projects');
    project.fetch();
    this.app.dataToRefresh = project;
  },

  editProject: function(slug) {
    this.app.debug("editProject");
    this.app.view.spinStart();
    var project = new models.Project({ id: slug }),
        view = new views.EditProject({ model: project, app: this.app });
    this.app.view.display( view );
    this.app.view.setTab('projects');
    project.fetch();
    this.app.dataToRefresh = null;
  }
});
