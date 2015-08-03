require 'work_dir'
require 'date'

module Autotune
  # project a blueprint
  class BuildJob < ActiveJob::Base
    queue_as :default

    def perform(project, target = :preview, force_sync = false)
      out = nil
      # Create a new repo object based on the projects working dir
      repo = WorkDir.repo(project.working_dir,
                          Rails.configuration.autotune.build_environment)

      # Make sure the repo exists and is up to date (if necessary)
      SyncProjectJob.perform_now(project) if !repo.exist? || force_sync

      # Add a few extras to the build data
      build_data = project.data.dup
      build_data.update(
        'title' => project.title,
        'slug' => project.slug,
        'theme' => project.theme.value)

      # Get the deployer object
      deployer = Autotune.find_deployment(target, project)

      # Run the before build deployer hook
      deployer.before_build(build_data, project)

      # Run the build
      repo.working_dir do
        project.output = repo.cmd(BLUEPRINT_BUILD_COMMAND, :stdin_data => build_data.to_json)
      end

      # Upload build
      deployer.deploy(project.deploy_dir, project.slug)

      # Create screenshots (has to happen after upload)
      url = deployer.url_for(project, project.slug)
      phantom = WorkDir.phantom(project.deploy_dir)
      phantom.capture_screenshot(get_full_url(url)) if phantom.phantomjs?

      # Upload screens
      phantom.screenshots.each do |filename|
        deployer.deploy_file(project.deploy_dir, project.slug, filename)
      end

      # Set status and save project
      project.status = 'built'
      project.published_at = DateTime.current if target == :publish
      project.save!
    rescue => exc
      # If the command failed, raise a red flag
      logger.error(exc)
      out ||= "#{exc.message}\n#{exc.backtrace.join("\n")}"
      project.update!(:output => out, :status => 'broken')
      raise
    end

    private

    def get_full_url(url)
      return url if url.start_with?('http')
      url.start_with?('//') ? 'http:' + url : 'http://localhost:3000' + url
    end
  end
end
