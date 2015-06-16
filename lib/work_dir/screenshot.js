var WebPage = require('webpage');
var System = require('system');
address = System.args[1];

page1 = WebPage.create();
page1.viewportSize = {
  width: 975,
  height: 500
};
page1.open(address);
page1.onLoadFinished = function() {
   setTimeout(function() {
    page1.render('./screenshots/screenshot_l.png');
    page1.close();
}, 3000);}

page2 = WebPage.create();
page2.viewportSize = {
  width: 720,
  height: 400
};
page2.open(address);
page2.onLoadFinished = function() {
   setTimeout(function() {
    page2.render('./screenshots/screenshot_m.png');
}, 3000);}

page3 = WebPage.create();
page3.viewportSize = {
  width: 400,
  height: 200
};
page3.open(address);
page3.onLoadFinished = function() {
   setTimeout(function() {
    page3.render('./screenshots/screenshot_s.png');
    phantom.exit();
}, 3000);}
