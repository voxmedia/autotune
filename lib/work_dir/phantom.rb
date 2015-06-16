require 'work_dir/base'

module WorkDir
  # A static website
  class Phantom < Base
    def capture_screenshot(url)
      working_dir do
        cmd 'echo "var WebPage = require(\'webpage\');
            var System = require(\'system\');
            address = System.args[1];
            page = WebPage.create();
            page.viewportSize = {
              width: 975,
              height: 500
            };
            page.open(address);
            page.onLoadFinished = function() {
               setTimeout(function() {
                page.render(\'screenshotL.png\');
                page.close();
            }, 2000);}

            page2 = WebPage.create();
            page2.viewportSize = {
              width: 720,
              height: 400
            };
            page2.open(address);
            page2.onLoadFinished = function() {
               setTimeout(function() {
                page2.render(\'screenshotM.png\');
            }, 2000);}
            
            page3 = WebPage.create();
            page3.viewportSize = {
              width: 400,
              height: 200
            };
            page3.open(address);
            page3.onLoadFinished = function() {
               setTimeout(function() {
                page3.render(\'screenshotS.png\');
                phantom.exit();
            }, 2000);}" > screenshot.js'
        phantomjs 'screenshot.js', url
        # rm 'screenshot.js'
      end
    end

    private
    def phantomjs(*args)
      cmd(*['phantomjs'] + args)
    end
  end
end
