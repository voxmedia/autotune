var Backbone = require('backbone'),
    blueprints = require('./fixtures/blueprints'),
    projects = require('./fixtures/projects');

Backbone.sync = function(method, model, options) {
  if ( method === 'create' ) {
    projects.append(model.attributes);
  } else if ( method === 'update' ) {
  } else if ( method === 'read' ) {
  } else if ( method === 'delete' ) {
  } else {
    throw 'wat';
  }
};
