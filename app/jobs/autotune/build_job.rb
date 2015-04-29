require 'work_dir'

module Autotune
  # project a blueprint
  class BuildJob < ActiveJob::Base
    queue_as :default

    def perform(project, mode = 'preview')
      out = nil
      # Create a new snapshot object based on the projects working dir
      snapshot = WorkDir.snapshot(project.working_dir,
                                  Rails.configuration.autotune.build_environment)
      # Setup the snapshot if it's not already. We don't want to update
      # our snapshot, we just need it to exist
      SyncProjectJob.perform_now(project) unless snapshot.exist?
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
      ws = WorkDir.website(snapshot.expand('build'))
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
