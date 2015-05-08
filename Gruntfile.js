'use strict';

module.exports = function(grunt) {

  // Project configuration.
  grunt.initConfig({
    // Metadata.
    pkg: grunt.file.readJSON('package.json'),
    banner: '/*! <%= pkg.name %> - v<%= pkg.version %> - ' +
      '<%= pkg.homepage ? "* " + pkg.homepage + "\\n" : "" %>' +
      '* Copyright (c) <%= grunt.template.today("yyyy") %> <%= pkg.author.name %>;' +
      ' Licensed <%= _.pluck(pkg.licenses, "type").join(", ") %> */\n',
    // Task configuration.
    browserify: {
      options: {
        banner: '<%= banner %>'
      },
      dist: {
        files: {
          'app/assets/javascripts/autotune/application.js': ['appjs/app.js']
        }
      }
    },
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
      }
    },
    watch: {
      gruntfile: {
        files: '<%= jshint.gruntfile.src %>',
        tasks: ['jshint:gruntfile']
      },
      lib: {
        files: ['appjs/*.js', 'appjs/**/*.js', 'appjs/**/*.ejs'],
        tasks: ['jshint:lib', 'browserify']
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
  grunt.loadNpmTasks('grunt-browserify');
  grunt.loadNpmTasks('grunt-notify');

  grunt.task.run('notify_hooks');

  // Default task.
  grunt.registerTask('default', ['jshint', 'browserify']);

};
