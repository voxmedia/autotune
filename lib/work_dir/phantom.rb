require 'work_dir/base'

module WorkDir
  # A static website
  class Phantom < Base
    def capture_screenshot(url)
      return unless phantomJS?
      working_dir do
        cp '../../../../autotune/lib/work_dir/screenshot.js', 'screenshot.js'
        phantomjs 'screenshot.js', url
        rm 'screenshot.js'
      end
    end

    private
    def phantomjs(*args)
      cmd(*['phantomjs'] + args)
    end
  end
end
