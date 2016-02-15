var test = require('../test_helper'),
    helpers = require('../../appjs/helpers'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    Application = require('../../appjs/app');

test('render', function(t) {
  t.plan(1);

  var template = _.template('<%=slugify( item ) %>');

  t.equal(
    helpers.render( template, { item: 'Hello World!' } ),
    'hello-world');

  t.end();
});

test('get objects', function(t) {
  t.plan(1);

  var template = _.template('<%= getObjects().length %>');

  t.equal(
    helpers.render( template, {
      collection: new Backbone.Collection([{ foo: 'yea' }])
    } ),
    '1');

  t.end();
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

  t.end();
});

// test('has role', function(t) {
//   t.plan(1);
//   var template = _.template('<%= hasRole( role ) ? true : false %>');

//   //Application.prototype.extend maybe?
//   console.log(
//     helpers.render( template, {
//       role: 'superuser',
//       app: {
//         user: {
//           attributes: {
//             meta: {
//               roles: ['superuser']
//             }
//           }
//         }
//       }
//     })
//   );

//   t.end();
// });

test('has next page', function(t) {
  t.plan(2);

  var template = _.template('<%= hasNextPage() ? "true" : "false" %>');

  t.equal(
    helpers.render( template, {
      collection: new Backbone.PageableCollection([], {
        "state": {
          "firstPage": 0,
          "currentPage": 0,
          "lastPage": 1
        }
      })
    }),
  'true');

  t.equal(
    helpers.render( template, {
      collection: new Backbone.PageableCollection([], {
        "state": {
          "firstPage": 0,
          "currentPage": 1,
          "lastPage": 1
        }
      })
    }),
  'false');

  t.end();
});

test('has previous page', function(t) {
  t.plan(2);

  var template = _.template('<%= hasPreviousPage() ? "true" : "false" %>');

  t.equal(
    helpers.render( template, {
      collection: new Backbone.PageableCollection([], {
        "state": {
          "firstPage": 0,
          "currentPage": 1,
          "lastPage": 1
        }
      })
    }),
  'true');

  t.equal(
    helpers.render( template, {
      collection: new Backbone.PageableCollection([], {
        "state": {
          "firstPage": 0,
          "currentPage": 0,
          "lastPage": 1
        }
      })
    }),
  'false');

  t.end();
});

test('get page url', function(t) {
  t.plan(1);
  
  var template = _.template('<%= getPageUrl(page) %>');

  t.equal(
    helpers.render( template, {
      page: 5,
      collection: new Backbone.PageableCollection.extend([], {
        "url": "/projects"
      })
    }
  ), '/projects?page=5');

  t.end();
});

test('get next page url', function(t) {
  t.plan(1);

  var template = _.template('<%= getNextPageUrl() %>');

  t.equal(
    helpers.render( template, {
      collection: new Backbone.PageableCollection.extend([], {
        "url": "/projects",
        "state": {
          "firstPage": 0,
          "currentPage": 1,
          "lastPage": 2
        }
      })
    }),
  '/projects?page=2');

  t.end();
});

test('get previous page url', function(t) {
  t.plan(1);

  var template = _.template('<%= getPreviousPageUrl() %>');

  t.equal(
    helpers.render( template, {
      collection: new Backbone.PageableCollection.extend([], {
        "url": "/projects",
        "state": {
          "firstPage": 0,
          "currentPage": 1,
          "lastPage": 2
        }
      })
    }),
  '/projects?page=0');

  t.end();
});
