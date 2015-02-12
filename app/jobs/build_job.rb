BLUEPRINT_BUILD_COMMAND = './autotune-build'

# build a blueprint
class BuildJob < ActiveJob::Base
  queue_as :default

  def perform(build)
    out, s = Open3.capture2e(
      # env,
      BLUEPRINT_BUILD_COMMAND,
      :stdin_data => build.data.to_json,
      :chdir => build.blueprint.working_dir)
    build.update!(
      :output => out,
      :status => (s.success? ? 'built' : 'broken'))
  end
end
