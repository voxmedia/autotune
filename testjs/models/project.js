var test = require('prova');

console.log('here?');

test('timing test', function (t) {
  t.plan(2);

  console.log('here!');

  t.equal(typeof Date.now, 'function');
  var start = Date.now();

  setTimeout(function () {
    t.equal(Date.now() - start, 100);
  }, 100);
});
