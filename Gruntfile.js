'use strict';

module.exports = function(grunt) {

  // Project configuration.
  grunt.initConfig({
    // Metadata.
    pkg: grunt.file.readJSON('package.json'),
    // Task configuration.
    jshint: {
      options: {
        jshintrc: '.jshintrc',
        ignores: ['appjs/vendor/*']
      },
      gruntfile: {
        src: 'Gruntfile.js'
      },
      lib: {
        options: {
          jshintrc: 'appjs/.jshintrc',
          ignores: ['appjs/vendor/*']
        },
        src: ['appjs/**/*.js']
      },
      test: {
        options: {
          jshintrc: 'testjs/.jshintrc'
        },
        src: ['testjs/**/*.js']
      }
    },
    watch: {
      gruntfile: {
        files: '<%= jshint.gruntfile.src %>',
        tasks: ['jshint:gruntfile']
      },
      lib: {
        files: ['appjs/*.js', 'appjs/**/*.js', 'appjs/**/*.ejs'],
        tasks: ['jshint:lib']
      },
      test: {
        files: ['testjs/test.js', 'testjs/**/*.js'],
        tasks: ['jshint:lib', 'jshint:test']
      }
    },
    notify_hooks: {
      options: {
        success: true
      }
    }
  });

  // These plugins provide necessary tasks.
  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-notify');

  grunt.task.run('notify_hooks');

  // Default task.
  grunt.registerTask('default', ['jshint']);

};
