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
  page.open(address);

  page.onError = function(){
    page.close();
    phantom.exit();
  };

  page.onLoadFinished = setTimeout(function() {
    if(processed) { return; }
    processed = true;
    page.render(screenshots[index].filename);
    page.close();
    index++;
    // Give it a second before calling next.
    // Phantom runs into some sort of race condition without this
    setTimeout(nextPage, 1000);
  }, 3000);
}

function nextPage(){
  if(!screenshots[index]){
    phantom.exit();
  }
  capturescreen();
}

nextPage();
//exit if not done after 20 seconds
setTimeout(function(){ phantom.exit(); }, 20000);
