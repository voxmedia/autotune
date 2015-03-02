"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('./models'),
    BaseView = require('./views/FormView');

module.exports = {
  ListBlueprints: BaseView.extend({
    template: require('./templates/blueprint_list.ejs')
  }),
  EditBlueprint: BaseView.extend({
    template: require('./templates/blueprint_form.ejs')
  }),
  ShowBlueprint: BaseView.extend({
    template: require('./templates/blueprint.ejs')
  }),
  ChooseBlueprint: BaseView.extend({
    template: require('./templates/blueprint_chooser.ejs')
  }),
  ListProjects: BaseView.extend({
    template: require('./templates/project_list.ejs')
  }),
  EditProject: BaseView.extend({
    template: require('./templates/project_form.ejs'),
    afterRender: function() {
      var $form = this.$el.find('#projectForm');
      if(_.isUndefined(this.model.blueprint.attributes['config']['form'])) {
        this.error('This blueprint does not have a form!');
      } else {
        $form.alpaca(this.model.blueprint.attributes['config']['form']);
      }
    }
  }),
  ShowProject: BaseView.extend({
    template: require('./templates/project.ejs')
  })
};
