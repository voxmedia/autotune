/* globals phantom, window, document */
var WebPage = require('webpage'),
    System = require('system'),
    address = System.args[1],
    finishedJobs = 0;

// All the sizes to screenshot.
// Note: PhantomJs uses the heights specified here as a min-height criteria
var screenshots = [
  {'dimensions' : [970,300],
    'filename': './screenshots/screenshot_l.png'},
  {'dimensions' : [720,300],
    'filename': './screenshots/screenshot_m.png'},
  {'dimensions' : [400,200],
    'filename': './screenshots/screenshot_s.png'}
];

function done() {
  finishedJobs++;
  if ( finishedJobs >= screenshots.length ) {
    console.log('Finished');
    phantom.exit(0);
  }
}

function captureScreen(opts){
  var page = WebPage.create(),
      finished = false;
  page.viewportSize = {
    width: opts.dimensions[0],
    height: opts.dimensions[1]
  };
  page.settings.userAgent = 'Mozilla/5.0 (Windows NT 6.0; WOW64) AppleWebKit/535.7 (KHTML, like Gecko) Chrome/16.0.912.75 Safari/535.7';
  page.customHeaders = {'Referer': address};
  console.log('Capture ' + opts.dimensions.join('x'));

  page.open(address);
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
      console.log('Page loaded at '+opts.dimensions.join('x'));
      page.evaluate(function() {
        document.onreadystatechange = function() {
          if (document.readyState === 'complete') {
            window.callPhantom('gtg');
          }
        };
      });
    }
  };
}

screenshots.forEach(function(s) {
  captureScreen(s);
});

//exit if not done after 20 seconds
setTimeout(function(){ phantom.exit(1); }, 20000);
