"use strict";

var $ = require('jquery'),
    Backbone = require('backbone'),
    models = require('./models'),
    views = require('./views'),
    Spinner = require('spin.js');

function display(view) {
  $('#main')
    .empty()
    .append(view.$el);
}

var spinner = new Spinner({color:'#333', lines: 12});

function spinStart() {
  spinner.spin(
    document.getElementById('spinner'));
}

function spinStop() {
  spinner.stop();
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

  listBlueprints: function() {
    console.log("listBlueprints");
    setTab('blueprints');
    var blueprints = this.blueprints = new models.BlueprintCollection();
    spinStart();
    blueprints.fetch().always(function() {
      var view = new views.ListBlueprints({collection: blueprints});
      display(view);
      spinStop();
    });
  },

  newBlueprint: function() {
    console.log("newBlueprint");
    setTab('');
    display( new views.EditBlueprint({ model: new models.Blueprint() }));
  },

  showBlueprint: function(slug) {
    console.log("showBlueprint");
    setTab('');
    var blueprint = new models.Blueprint({id: slug});
    spinStart();
    blueprint.fetch().always(function() {
      display( new views.ShowBlueprint({ model: blueprint }) );
      spinStop();
    });
  },

  editBlueprint: function(slug) {
    console.log("editBlueprint");
    setTab('');
    var blueprint = new models.Blueprint({id: slug});
    spinStart();
    blueprint.fetch().always(function() {
      display( new views.EditBlueprint({ model: blueprint }) );
      spinStop();
    });
  },

  chooseBlueprint: function() {
    console.log("chooseBlueprint");
    setTab('');
    var blueprints = new models.BlueprintCollection();
    spinStart();
    blueprints.fetch().always(function() {
      display( new views.ChooseBlueprint({ collection: blueprints }) );
      spinStop();
    });
  },

  listProjects: function() {
    console.log("listProjects");
    setTab('projects');
    var projects = new models.ProjectCollection();
    spinStart();
    projects.fetch().always(function() {
      display( new views.ListProjects({ collection: projects }) );
      spinStop();
    });
  },

  newProject: function(slug) {
    console.log("newProject");
    setTab('');
    var blueprint = new models.Blueprint({id: slug});
    spinStart();
    blueprint.fetch().always(function() {
      display( new views.EditProject({ model: new models.Project({ blueprint: blueprint }) }) );
      spinStop();
    });
  },

  showProject: function(slug) {
    console.log("showProject");
    setTab('');
    var project = new models.Project({slug: slug});
    spinStart();
    project.fetch().always(function() {
      display( new views.ShowProject({ model: project }) );
      spinStop();
    });
  },

  editProject: function( slug) {
    console.log("editProject");
    setTab('');
    var project = new models.project({slug: slug});
    spinStart();
    project.fetch().always(function() {
      display( new views.EditProject({ model: project }) );
      spinStop();
    });
  }
});
