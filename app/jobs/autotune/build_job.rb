require 'work_dir'
require 'date'
require 'logger'
require 'stringio'

module Autotune
  # project a blueprint
  class BuildJob < ActiveJob::Base
    queue_as :default

    lock_job :retry => 20.seconds do
      arguments.first.to_gid_param
    end

    unique_job :with => :payload

    def perform(project, target: 'preview')
      # Create a new repo object based on the projects working dir
      repo = WorkDir.repo(project.working_dir,
                          Rails.configuration.autotune.build_environment)

      # Make sure the repo exists and is up to date (if necessary)
      raise 'Missing files!' unless repo.exist?

      # Setup a new logger that logs to a string. The resulting log will
      # be saved to the output field of the project.
      out = StringIO.new
      outlogger = Logger.new out
      outlogger.formatter = proc do |severity, datetime, _progname, msg|
        "#{datetime.strftime('%b %e %H:%M %Z')}\t#{severity}\t#{msg}\n"
      end

      # Add a few extras to the build data
      build_data = project.data.deep_dup
      build_data.update(
        'title' => project.title,
        'slug' => project.slug,
        'theme' => project.theme.value)

      # Get the deployer object
      deployer = Autotune.new_deployer(
        target.to_sym, project, :logger => outlogger)

      # Run the before build deployer hook
      deployer.before_build(build_data, repo.env)

      # Run the build
      repo.working_dir do
        outlogger.info(repo.cmd(
          BLUEPRINT_BUILD_COMMAND, :stdin_data => build_data.to_json))
      end

      # Upload build
      deployer.deploy(project.deploy_dir)

      # Create screenshots (has to happen after upload)
      url = deployer.base_url
      phantom = WorkDir.phantom(project.deploy_dir)
      phantom.capture_screenshot(get_full_url(url)) if phantom.phantomjs?

      # Upload screens
      phantom.screenshots.each do |filename|
        deployer.deploy_file(project.deploy_dir, filename)
      end

      # Set status and save project
      project.published_at = DateTime.current if target.to_sym == :publish
      project.status = 'built'
    rescue => exc
      # If the command failed, raise a red flag
      msg = exc.message + "\n" + exc.backtrace.join("\n")
      logger.error(msg)
      outlogger.error(msg)
      project.status = 'broken'
      raise
    ensure
      # Always make sure to save the log and the project
      out.rewind
      project.output = out.read
      project.save!
      outlogger.close
    end

    private

    def get_full_url(url)
      return url if url.start_with?('http')
      url.start_with?('//') ? 'http:' + url : 'http://localhost:3000' + url
    end
  end
end
