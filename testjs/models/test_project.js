var test = require('prova'),
    Project = require('../../appjs/models/project');

require('../test_helper');

test('get project', function(t) {
  t.plan(1);

  var p = new Project({id: 'example-build-one'});
  p.fetch().then(function() {
    t.equal(p.get('slug'),
            'example-build-one', 'Valid slug');
  }, t.fail);
});
