var test = require('../test_helper'),
    _ = require('underscore'),
    models = require('../../appjs/models'),
    Messages = require('../../appjs/messages'),
    Backbone = require('backbone');

var messages;

function setup() {
  messages = new Messages();
  messages.start();
}

function teardown() {
  messages.stop();
  messages.off();
}

test('should get messages', function(t) {
  t.timeoutAfter(5000);
  t.plan(1);

  messages.on('ping', function(payload) {
    t.equal(payload, 'pong', 'Call back worked');
  });

  messages.send('ping', 'pong')
          .catch(function(msg) { t.fail(msg); });
}).on('prerun', setup).on('end', teardown);

test('editing messages', function(t) {
  t.timeoutAfter(5000);
  t.plan(3);

  var expected_payload = {
    model: 'blueprint', id: '1'
  };

  messages.on('open', function(payload) {
    t.deepEqual(payload, expected_payload, 'Valid data for open event');
  });

  messages.on('open:blueprint', function(payload) {
    t.deepEqual(payload, expected_payload, 'Valid data for open:blueprint event');
  });

  messages.on('open:blueprint:1', function(payload) {
    t.deepEqual(payload, expected_payload, 'Valid data for open:blueprint:1 event');
  });

  messages.send('open', expected_payload);
}).on('prerun', setup).on('end', teardown);

test('updating a blueprint should create a message', function(t) {
  var bp = new models.Blueprint({id: 'example-blueprint'});
  var prev_status;

  t.timeoutAfter(5000);

  t.plan(4);

  Promise.resolve(bp.fetch()).then(function() {
    t.ok(bp.id, 'Should have blueprint id');

    var expected_payload = {
      model: 'blueprint', id: bp.id, status: 'ready'
    };

    messages.once('change', function(payload) {
      t.deepEqual(payload, expected_payload, 'Valid data for change event');
    });

    messages.once('change:blueprint', function(payload) {
      t.deepEqual(payload, expected_payload, 'Valid data for change:blueprint event');
    });

    var evtName = 'change:blueprint:' + bp.id;
    messages.once(evtName, function(payload) {
      t.deepEqual(payload, expected_payload, 'Valid data for '+evtName+' event');
    });

    prev_status = bp.get('status');

    return bp.save({status: 'ready'});
  }, function(jqxhr) {
    var msg = 'Blueprint fetch failed: '+( jqxhr.responseText || jqxhr.responseXML || jqxhr.responseJSON || jqxhr.statusText );
    t.end(new Error(msg));
  }).then(function() {
    if ( prev_status ) { return bp.save({status: prev_status}); }
  }, function(jqxhr) {
    var msg = 'Blueprint save failed: '+( jqxhr.responseText || jqxhr.responseXML || jqxhr.responseJSON || jqxhr.statusText );
    t.end(new Error(msg));
  });
}).on('prerun', setup).on('end', teardown);

test('updating a project should create a message', function(t) {
  var p = new models.Project({id: 'example-build-one'});
  var prev_status;

  t.skip('TODO: Updating a project triggers a job which fails in this test rig');
  return t.end();

  t.timeoutAfter(5000);
  t.plan(4);

  Promise.resolve(p.fetch()).then(function() {
    t.ok(p.id, 'Should have project id');

    var expectedPayload = {
      model: 'project', id: p.id.toString(), status: 'building'
    };
    messages.once('change', function(payload) {
      t.deepEqual(payload, expectedPayload, 'Valid data for change event');
    });

    messages.once('change:project', function(payload) {
      t.deepEqual(payload, expectedPayload, 'Valid data for change event');
    });

    var evtName = 'change:project:' + p.id;
    messages.once(evtName, function(payload) {
      t.deepEqual(payload, expectedPayload, 'Valid data for '+evtName+' event');
    });

    prev_status = p.get('status');

    return p.save({status: 'building'});
  }, function(jqxhr) {
    var msg = 'Project fetch failed: '+( jqxhr.responseText || jqxhr.responseXML || jqxhr.responseJSON || jqxhr.statusText );
    t.end(new Error(msg));
    return Promise.reject(msg);
  }).then(function() {
    if ( prev_status ) { return p.save({status: prev_status}); }
  }, function(jqxhr) {
    var msg = 'Project save failed: '+( jqxhr.responseText || jqxhr.responseXML || jqxhr.responseJSON || jqxhr.statusText );
    t.end(new Error(msg));
  });
}).on('prerun', setup).on('end', teardown);
