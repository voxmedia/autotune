require 'work_dir'

module Autotune
  # project a blueprint
  class BuildJob < ActiveJob::Base
    queue_as :default

    def perform(project)
      out = nil
      # Create a new snapshot object based on the projects working dir
      snapshot = WorkDir.snapshot(project.working_dir,
                                  Rails.configuration.autotune.environment)
      # Setup the snapshot if it's not already. We don't want to update
      # our snapshot, we just need it to exist
      SyncProjectJob.perform_now(project) unless snapshot.exist?
      # Add a few extras to the build data
      build_data = project.data.dup
      build_data['base_url'] = project.preview_url
      # Run the build
      out = snapshot.build(project.data)
      # Upload build
      ws = WorkDir.website(
        snapshot.expand('build'),
        Rails.configuration.autotune.environment)
      ws.deploy(File.join(
        Rails.configuration.autotune.preview[:connect], project.slug))
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
