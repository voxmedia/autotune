var WebPage = require('webpage');
var System = require('system');
address = System.args[1];
var index = 0;

var screenshots = [
  {"dimensions" : [975,500],
  "filename": './screenshots/screenshot_l.png'},
  {"dimensions" : [720,400],
  "filename": './screenshots/screenshot_m.png'},
  {"dimensions" : [400,200],
  "filename": './screenshots/screenshot_s.png'}
];

var capturescreen = function(dimensions, filename){
  var page = WebPage.create();
  page.viewportSize = {
    width: dimensions[0],
    height: dimensions[1]
  };
  page.open(address);
  page.onLoadFinished = setTimeout(function() {
      page.render(filename);
      page.close();
      index++;
      // Give it a second before calling next. 
      // Phantom runs into some sort of race condition without this
      setTimeout(nextPage, 1000); 
  }, 3000);
}

var nextPage = function(){
  if(!screenshots[index]){
    phantom.exit();
  }
  capturescreen(screenshots[index].dimensions, screenshots[index].filename);
}

nextPage();