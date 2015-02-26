"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('./models'),
    BaseView = require('./views/BaseView');

module.exports = {
  ListBlueprints: BaseView.extend({
    template: require('./templates/blueprint_list.ejs'),
    beforeRender: function() {
      $('.modal').modal('hide');
    }
  }),
  ShowBlueprint: BaseView.extend({
    template: require('./templates/blueprint.ejs'),
  }),
  ListBuilds: BaseView.extend({
    template: require('./templates/build_list.ejs'),
  }),
  EditBuild: BaseView.extend({
    template: require('./templates/build_edit.ejs'),
    afterRender: function() {
      var $form = this.$el.find('#buildForm');
      if(_.isUndefined(this.model.blueprint.attributes['form'])) {
        this.error('This blueprint does not have a form setup!');
      } else {
        $form.alpaca(this.model.blueprint.attributes['form']);
      }
    }
  }),
  ShowBuild: BaseView.extend({
    template: require('./templates/build.ejs')
  })
};
