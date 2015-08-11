var WebPage = require('webpage'),
    System = require('system'),
    address = System.args[1],
    index = 0;

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

function capturescreen(){
  var processed = false;
  var page = WebPage.create();
  page.viewportSize = {
    width: screenshots[index].dimensions[0],
    height: screenshots[index].dimensions[1]
  };
  console.log('Capture ' + screenshots[index].dimensions.join('x'));

  page.open(address);
  page.onLoadFinished = function(status){
    if ( status === 'fail' ) {
      console.error('Failed to load '+address);
      phantom.exit(1);
    } else {
      console.log('Page loaded');
      setTimeout(function() {
        if(processed) { return; }
        console.log('Saving image ' + screenshots[index].filename);
        processed = true;
        page.render(screenshots[index].filename);
        page.close();
        index++;
        // Give it a second before calling next.
        // Phantom runs into some sort of race condition without this
        setTimeout(nextPage, 1000);
      }, 2000);
    }
  }
}

function nextPage(){
  if(!screenshots[index]){
    console.log('Finished');
    phantom.exit(0);
  }
  capturescreen();
}

nextPage();
//exit if not done after 20 seconds
setTimeout(function(){ phantom.exit(1); }, 20000);
