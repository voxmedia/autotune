var test = require('../test_helper'),
    Project = require('../../appjs/models/project');

test('get project', function(t) {
  t.plan(3);

  try {
    var p = new Project({id: 'example-build-one'});
    t.equal(p.id, 'example-build-one');
    p.fetch().then(function() {
      t.equal(p.get('slug'),
              'example-build-one', 'Valid slug');
      t.equal(p.get('title'),
              'Example build one', 'Valid title');
    }, function(jqXHR, status, error) {
      if ( error ) {
        t.end(error);
      } else {
        t.end(new Error('ajax request failed'));
      }
    });
  } catch(e) {
    t.end(e);
  }
});
