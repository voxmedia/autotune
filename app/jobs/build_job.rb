# build a blueprint
class BuildJob < ActiveJob::Base
  queue_as :default

  def perform(build)
    out = build.snapshot.build build.data
    build.update!(:output => out, :status => 'built')
  end
end
