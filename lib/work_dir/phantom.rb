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
          width: 800,
          height: 400
        };
        page.open(address);
        page.onLoadFinished = function() {
           setTimeout(function() {
            page.render(\'screenshot.png\');
            phantom.exit();
        }, 1000);}" > screenshot.js'
        phantomjs 'screenshot.js', url
        rm 'phantomjs'
      end
    end

    private
    def phantomjs(*args)
      cmd(*['phantomjs'] + args)
    end
  end
end
