"use strict";

var $ = require('jquery'),
    Backbone = require('backbone'),
    models = require('./models'),
    views = require('./views');

function display(view) {
  $('#main')
    .empty()
    .append(view.$el);
}

module.exports = Backbone.Router.extend({

  routes: {
    "": "listBlueprints",
    "blueprints/": "listBlueprints",
    "blueprints/:name/": "showBlueprint",
    "blueprints/:name/builds/": "listBuilds",
    "blueprints/:name/builds/new": "newBuild",
    "blueprints/:name/builds/:slug/": "showBuild",
    "blueprints/:name/builds/:slug/edit": "editBuild"
  },

  listBlueprints: function() {
    console.log("listBlueprints");
    var blueprints = this.blueprints = new models.BlueprintCollection();
    blueprints.fetch().always(function() {
      var view = new views.ListBlueprints({collection: blueprints});
      display(view);
    });
  },

  showBlueprint: function(name) {
    console.log("showBlueprint");
    var blueprint = new models.Blueprint({id: name});
    blueprint.fetch().always(function() {
      var view = new views.ShowBlueprint({model: blueprint});
      display(view);
    });
  },

  listBuilds: function(name) {
    console.log("listBuilds");
    var blueprint = new models.Blueprint({id: name});
    blueprint.fetch().always(function() {
      blueprint.builds.fetch().always(function() {
        var view = new views.ListBuilds({collection: blueprint.builds});
        display(view);
      });
    });
  },

  newBuild: function(name, slug) {
    console.log("newBuild");
    var blueprint = new models.Blueprint({id: name});
    blueprint.fetch().always(function() {
      var build = new models.Build({blueprint: blueprint});
      var view = new views.EditBuild({model: build});
      display(view);
    });
  },

  showBuild: function(name, slug) {
    console.log("showBuild");
    var build = new models.Build({blueprint_name: name, slug: slug});
    build.fetch().always(function() {
      var view = new views.ShowBuild({model: build});
      display(view);
    });
  },

  editBuild: function(name, slug) {
    console.log("editBuild");
    var build = new models.build({blueprint_name: name, slug: slug});
    build.fetch().always(function() {
      var view = new views.EditBuild({model: build});
      display(view);
    });
  },

});
