require('../test_helper');

var test = require('prova'),
    Project = require('../../appjs/models/project');

test('get project', function(t) {
  t.plan(2);

  try {
    var p = new Project({id: 'example-build-one'});
    t.equal(p.id, 'example-build-one');
    console.log('here');
    p.fetch().then(function() {
      console.log('now here');
      console.log(p.get('slug'));
      t.equal(p.get('slug'),
              'example-build-one', 'Valid slug');
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
