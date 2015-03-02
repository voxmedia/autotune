# project a blueprint
class BuildJob < ActiveJob::Base
  queue_as :default

  def perform(project)
    project.sync_snapshot unless project.snapshot.exist?
    out = project.snapshot.build(project.data)
    project.update!(:output => out, :status => 'built')
  end
end
