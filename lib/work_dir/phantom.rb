require 'work_dir/base'

module WorkDir
  # A static website
  class Phantom < Base
    def capture_screenshot(url)
      return unless phantomjs?
      working_dir do
        script_path = File.expand_path('../screenshot.js', __FILE__).to_s
        phantomjs script_path, url
      end
    end

    # Is phantomJS installed?
    def phantomjs?
      cmd 'which', 'phantomjs'
      return true
    rescue
      return false
    end

    private

    def phantomjs(*args)
      cmd(*['phantomjs'] + args)
    end
  end
end
