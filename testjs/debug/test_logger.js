var test = require('../test_helper'),
    logger = require('../../appjs/logger');

test('log', function(t) {
  t.plan(0);
  logger.log('Informational message');
  t.end();
});

test('debug - correct level', function(t) {
  t.plan(0);
  logger.level = 'debug';
  logger.debug('Debug message');
  t.end();
});

test('debug - incorrect level', function(t) {
  t.plan(0);
  logger.level = 'log';
  logger.debug('Debug message');
  t.end();
});

test('error', function(t) {
  t.plan(0);
  logger.error('Error message');
  t.end();
});