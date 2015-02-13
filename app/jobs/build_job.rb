# build a blueprint
class BuildJob < ActiveJob::Base
  queue_as :default

  def perform(build)
    build.blueprint.repo.update
    out = build.blueprint.repo.build build.data
    build.update!(:output => out, :status => 'built')
  rescue Repo::CommandError => exc
    logger.error(exc)
    update!(:status => 'broken')
    false
  end
end
