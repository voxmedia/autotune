# build a blueprint
class BuildJob < ActiveJob::Base
  queue_as :default

  def perform(build)
    build.sync_snapshot unless build.snapshot.exist?
    out = build.snapshot.build(build.data)
    build.update!(:output => out, :status => 'built')
  end
end
