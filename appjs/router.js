"use strict";

var $ = require('jquery'),
    Backbone = require('backbone'),
    models = require('./models'),
    views = require('./views'),
    queryString = require('query-string');

function display(view) {
  $('#main')
    .empty()
    .append(view.$el);
}

function spinStart() {
  $('#spinner').show();
}

function spinStop() {
  $('#spinner').fadeOut('fast');
}

function setTab(name) {
  $('#nav [data-tab]').removeClass('active');
  if(name) { $('#nav [data-tab='+name+']').addClass('active'); }
}

function clearError() {
  $('#notice').empty();
}

module.exports = Backbone.Router.extend({
  routes: {
    "": "listProjects",
    "blueprints": "listBlueprints",
    "blueprints/new": "newBlueprint",
    "blueprints/:slug": "showBlueprint",
    "blueprints/:slug/new_project": "newProject",
    "blueprints/:slug/edit": "editBlueprint",
    "projects": "listProjects",
    "projects/new": "chooseBlueprint",
    "projects/:slug": "showProject",
    "projects/:slug/edit": "editProject"
  },

  listBlueprints: function(params) {
    console.log("listBlueprints", params);
    spinStart();
    var blueprints = this.blueprints = new models.BlueprintCollection(),
        query = {};
    if(params) { query = queryString.parse(params); }
    blueprints.fetch({data: query}).always(function() {
      display( new views.ListBlueprints(
        {collection: blueprints, query: query}) );
      setTab('blueprints');
      spinStop();
    });
  },

  newBlueprint: function() {
    console.log("newBlueprint");
    setTab('blueprints');
    display( new views.EditBlueprint({ model: new models.Blueprint() }));
    spinStop();
  },

  showBlueprint: function(slug) {
    console.log("showBlueprint");
    spinStart();
    var blueprint = new models.Blueprint({id: slug});
    blueprint.fetch().always(function() {
      display( new views.ShowBlueprint({ model: blueprint }) );
      setTab('blueprints');
      spinStop();
    });
  },

  editBlueprint: function(slug) {
    console.log("editBlueprint");
    spinStart();
    var blueprint = new models.Blueprint({id: slug});
    blueprint.fetch().always(function() {
      display( new views.EditBlueprint({ model: blueprint }) );
      setTab('blueprints');
      spinStop();
    });
  },

  chooseBlueprint: function(params) {
    console.log("chooseBlueprint");
    spinStart();
    var blueprints = new models.BlueprintCollection(),
        query = {};
    if(params) { query = queryString.parse(params); }
    query['status'] = 'ready';
    blueprints.fetch({data: query}).always(function() {
      display( new views.ChooseBlueprint(
        { collection: blueprints, query: query }) );
      setTab('projects');
      spinStop();
    });
  },

  listProjects: function(params) {
    console.log("listProjects");
    spinStart();
    var projects = new models.ProjectCollection(),
        query = {};
    if(params) { query = queryString.parse(params); }
    projects.fetch({data: query}).always(function() {
      display( new views.ListProjects(
        { collection: projects, query: query }) );
      setTab('projects');
      spinStop();
    });
  },

  newProject: function(slug) {
    console.log("newProject");
    spinStart();
    var blueprint = new models.Blueprint({id: slug});
    blueprint.fetch().always(function() {
      display( new views.EditProject(
        { model: new models.Project({ blueprint: blueprint }) }) );
      setTab('projects');
      spinStop();
    });
  },

  showProject: function(slug) {
    console.log("showProject");
    spinStart();
    var project = new models.Project({id: slug});
    project.fetch().always(function() {
      display( new views.ShowProject({ model: project }) );
      setTab('projects');
      spinStop();
    });
  },

  editProject: function( slug) {
    console.log("editProject");
    spinStart();
    var project = new models.Project({id: slug});
    project.fetch().always(function() {
      project.blueprint = new models.Blueprint({id: project.get('blueprint_id')});
      project.blueprint.fetch().always(function() {
        display( new views.EditProject({ model: project }) );
        setTab('projects');
        spinStop();
      });
    });
  }
});
