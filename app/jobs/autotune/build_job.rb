require 'work_dir'
require 'date'

module Autotune
  # project a blueprint
  class BuildJob < ActiveJob::Base
    queue_as :default

    def perform(project, mode = 'preview', force_sync = false)
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
        'theme' => project.theme.value,
        'base_url' => (mode == :publish) ? project.publish_url : project.preview_url)

      # Run the build
      repo.working_dir do
        out = repo.cmd(BLUEPRINT_BUILD_COMMAND, :stdin_data => build_data.to_json)
      end

      # Upload build
      deploy_dir = project.blueprint_config['deploy_dir'] || 'build'
      ws = WorkDir.website(repo.expand(deploy_dir))
      if mode == 'publish'
        ws.deploy(File.join(
          Rails.configuration.autotune.publish[:connect], project.slug))

        # Save the results
        project.update!(
          :output => out, :status => 'built', :published_at => DateTime.current)
      else
        ws.deploy(File.join(
          Rails.configuration.autotune.preview[:connect], project.slug))

        # Save the results
        project.update!(:output => out, :status => 'built')
      end
    rescue => exc
      # If the command failed, raise a red flag
      logger.error(exc)
      out ||= "#{exc.message}\n#{exc.backtrace.join("\n")}"
      project.update!(:output => out, :status => 'broken')
      raise
    end
  end
end
