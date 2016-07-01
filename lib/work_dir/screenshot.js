/* globals phantom, window, document */
var WebPage = require('webpage'),
    System = require('system'),
    address = System.args[1],
    finishedJobs = 0,
    TIMEOUT = 90;

// All the sizes to screenshot.
// Note: PhantomJs uses the heights specified here as a min-height criteria
var screenshots = [
  {'dimensions' : [970,300],
    'pixelRatio': 2,
    'filename': './screenshots/screenshot_l@2.png'},
  {'dimensions' : [970,300],
    'filename': './screenshots/screenshot_l.png'},
  {'dimensions' : [720,300],
    'filename': './screenshots/screenshot_m.png'},
  {'dimensions' : [720,300],
    'pixelRatio': 2,
    'filename': './screenshots/screenshot_m@2.png'},
  {'dimensions' : [400,200],
    'filename': './screenshots/screenshot_s.png'},
  {'dimensions' : [400,200],
    'pixelRatio': 2,
    'filename': './screenshots/screenshot_s@2.png'}
];

function done() {
  finishedJobs++;
  if ( finishedJobs >= screenshots.length ) {
    console.log('Finished');
    phantom.exit(0);
  }
}

function consoleMessageCB(msg, lineNum, sourceId) {
  console.log('CONSOLE: ' + msg + ' (from line #' + lineNum + ' in "' + sourceId + '")');
}

function errorCB(msg, trace) {

  var msgStack = ['ERROR: ' + msg];

  if (trace && trace.length) {
    msgStack.push('TRACE:');
    trace.forEach(function(t) {
      msgStack.push(' -> ' + t.file + ': ' + t.line + (t.function ? ' (in function "' + t.function +'")' : ''));
    });
  }

  console.error(msgStack.join('\n'));

}

function resourceTimeoutCB(request) {
  console.error('Request timeout (#' + request.id + '): ' + JSON.stringify(request, null, 4));
}

function resourceErrorCB(resourceError) {
  console.error('Unable to load resource (#' + resourceError.id + 'URL:' + resourceError.url + ')');
  console.error('Error code: ' + resourceError.errorCode + '. Description: ' + resourceError.errorString);
}

function captureScreen(opts){
  var page = WebPage.create(),
      finished = false;
  page.viewportSize = {
    width: opts.dimensions[0] * (opts.pixelRatio || 1),
    height: opts.dimensions[1] * (opts.pixelRatio || 1)
  };
  page.zoomFactor = opts.pixelRatio;
  page.settings.userAgent = 'Mozilla/5.0 (Windows NT 6.0; WOW64) AppleWebKit/535.7 (KHTML, like Gecko) Chrome/16.0.912.75 Safari/535.7';
  page.customHeaders = {'Referer': address};

  console.log('Capture ' + opts.dimensions.join('x') + ' @' + (opts.pixelRatio || 1));

  page.open(address);

  page.onConsoleMessage = consoleMessageCB;
  page.onError = errorCB;
  page.onResourceError = resourceErrorCB;
  page.onResourceTimeout = resourceTimeoutCB;

  page.onCallback = function(data) {
    if ( data === 'gtg' ) {
      console.log('Saving image ' + opts.filename);
      page.render(opts.filename);
      page.close();
      done();
    }
  };
  page.onLoadFinished = function(status){
    if ( finished ) { return; }

    if ( status === 'fail' ) {
      console.error('Failed to load '+opts.dimensions.join('x'));
      done();
    } else {
      finished = true;
      console.log('Page loaded at '+opts.dimensions.join('x') + ' @' + (opts.pixelRatio || 1));
      page.evaluate(function() {
        function _phantomLoadCB() {
          if (document.readyState === 'complete') {
            setTimeout(function() { window.callPhantom('gtg'); }, 200);
          }
        }

        document.onreadystatechange = _phantomLoadCB;
        _phantomLoadCB();
      });
    }
  };
}

screenshots.forEach(function(s) {
  captureScreen(s);
});

// In case something hangs, kill it all after 90 seconds
setTimeout(function() {
  console.error("Waited " + TIMEOUT + " seconds, terminating");
  phantom.exit(1);
}, TIMEOUT*1000);
