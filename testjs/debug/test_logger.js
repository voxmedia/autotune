var test = require('../test_helper'),
    logger = require('../../appjs/logger');

test('log', function(t) {
  t.plan(1);
  t.equal('Informational message', logger.log('Informational message')[0]);
  t.end();
});

test('debug - correct level', function(t) {
  t.plan(1);
  logger.level = 'debug';
  t.true(logger.debug('Debug message'), 'prints to console');
  t.end();
});

test('debug - incorrect level', function(t) {
  t.plan(1);
  logger.level = 'log';
  t.false(logger.debug('Debug message'), 'does not print to console');
  t.end();
});

test('error', function(t) {
  t.plan(1);
  t.equal('Error message', logger.error('Error message')[0]);
  t.end();
});