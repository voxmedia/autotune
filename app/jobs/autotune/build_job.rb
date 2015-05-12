require 'work_dir'

module Autotune
  # project a blueprint
  class BuildJob < ActiveJob::Base
    queue_as :default

    def perform(project, mode = 'preview', force_sync = false)
      out = nil
      # Create a new snapshot object based on the projects working dir
      snapshot = WorkDir.snapshot(project.working_dir,
                                  Rails.configuration.autotune.build_environment)

      # Make sure the snapshot exists and is up to date (if necessary)
      SyncProjectJob.perform_now(project) if !snapshot.exist? || force_sync

      # Add a few extras to the build data
      build_data = project.data.dup
      if mode == :publish
        build_data['base_url'] = project.publish_url
      else
        build_data['base_url'] = project.preview_url
      end

      # Run the build
      out = snapshot.build(build_data)

      # Upload build
      deploy_dir = project.blueprint_config['deploy_dir'] || 'build'
      ws = WorkDir.website(snapshot.expand(deploy_dir))
      if mode == 'publish'
        ws.deploy(File.join(
          Rails.configuration.autotune.publish[:connect], project.slug))
      else
        ws.deploy(File.join(
          Rails.configuration.autotune.preview[:connect], project.slug))
      end

      # Save the results
      project.update!(:output => out, :status => 'built')
    rescue => exc
      # If the command failed, raise a red flag
      logger.error(exc)
      out ||= "#{exc.message}\n#{exc.backtrace.join("\n")}"
      project.update!(:output => out, :status => 'broken')
      raise
    end
  end
end
