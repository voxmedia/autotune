var test = require('../test_helper'),
    helpers = require('../../appjs/helpers'),
    _ = require('underscore'),
    Backbone = require('backbone');

test('render', function(t) {
  t.plan(1);

  var template = _.template('<%=slugify( item ) %>');

  t.equal(
    helpers.render( template, { item: 'Hello World!' } ),
    'hello-world');
});

test('get objects', function(t) {
  t.plan(1);

  var template = _.template('<%= getObjects().length %>');

  t.equal(
    helpers.render( template, {
      collection: new Backbone.Collection([{ foo: 'yea' }])
    } ),
    '1');
});

test('has objects', function(t) {
  t.plan(3);

  var template = _.template('<%= hasObjects() ? "true" : "false" %>');

  t.equal(
    helpers.render( template, {
      collection: new Backbone.Collection([{ foo: 'yea' }])
    } ),
    'true');

  t.equal(
    helpers.render( template, {
      collection: new Backbone.Collection([])
    } ),
    'false');

  t.equal(
    helpers.render( template ),
    'false');
});
