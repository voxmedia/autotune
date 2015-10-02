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
          'app/assets/javascripts/autotune/application.js': ['appjs/app.js'],
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
        tasks: ['jshint:lib', 'browserify']
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
  grunt.loadNpmTasks('grunt-browserify');
  grunt.loadNpmTasks('grunt-notify');

  grunt.task.run('notify_hooks');

  // Default task.
  grunt.registerTask('default', ['jshint', 'browserify']);

  // Testing
  grunt.registerTask('test', 'Run tests', function() {
    var done = this.async(),
        path = require('path'),
        spawn = require('child_process').spawn,
        prova = require.resolve('prova/bin/prova'),
        rails, rake, runner, timeout;

    grunt.log.writeln('Starting rails API');

    // reset the rails test db
    process.env['RAILS_ENV'] = 'test';
    rake = spawn('bundle', ['exec', 'rake', 'db:drop', 'db:create', 'db:migrate', 'db:fixtures:load']);
    rake.stderr.pipe(process.stderr, { end: false });
    //rake.stdout.pipe(process.stdout, { end: false });

    // Run the rails dummy app to provide the API
    rails = spawn('bundle',
                  ['exec', 'rails', 's', '-p', '3001', '-e', 'test'],
                  {cwd: path.normalize('./test/dummy')});

    // Capture rails error output and send to the terminal
    rails.stderr.pipe(process.stderr, { end: false });
    rails.stdout.pipe(process.stdout, { end: false });

    rails.on('close', function(code) {
      if (code !== 0) {
        if ( timeout ) {
          clearTimeout(timeout);
          done(new Error('Rails failed to start'));
        } else if ( runner ) {
          runner.kill('SIGINT');
        }
      }
    });

    timeout = setTimeout(function() {
      grunt.log.writeln('Running tests');
      timeout = false;
      // Use prova to run the tests
      runner = spawn(prova, ['-b', '-y', '/api=http://localhost:3001', 'testjs/*/test_*.js']);

      // Capture prova output and send to the terminal
      runner.stderr.pipe(process.stderr, { end: false });
      runner.stdout.pipe(process.stdout, { end: false });

      runner.on('close', function(code) {
        // When tests complete, stop the rails server
        rails.kill('SIGINT');
        if (code !== 0) {
          done(new Error('Javascript tests failed'));
        } else {
          done();
        }
      });
    }, 8000);
  });
};
