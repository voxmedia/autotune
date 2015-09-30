var test = require('prova'),
    path = require('path'),
    spawn = require('child_process').spawn;

var rails;

function startRails() {
  // Run the rails dummy app to provide the API
  rails = spawn('bundle',
                ['exec', 'rails', 's', '-e', 'test'],
                {cwd: path.normalize('./test/dummy')});
}

function stopRails() {
  rails.kill('SIGINT');
}

process.env['RAILS_ENV'] = 'test';
function reloadRails(cb) {
  spawn(
    'bundle', ['exec', 'rake', 'db:drop', 'db:create', 'db:fixtures:load']
  ).on('close', function(code) {
    if (code !== 0) {
      throw "Failed to reload rails";
    } else {
      cb();
    }
  });
}

module.exports = function() {
  var args = Array.prototype.slice.call(arguments);
  reloadRails(function() {
    test.apply(test, args);
  });
};
