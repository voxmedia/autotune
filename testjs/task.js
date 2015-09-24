'use strict';

module.exports = function (grunt) {
  // Testing
  grunt.registerTask('test', 'Run tests', function() {
    var done = this.async(),
        prova = require.resolve('prova/bin/prova');

    grunt.utils.spawn({
      cmd: prova, args: ['testjs/**/*.js']},
      function(error, result, code) {
      if (code !== 0) {
        done(new Error('Prova test failure. Exited with code ' + code));
      } else {
        done();
      }
    } );
  });
};
