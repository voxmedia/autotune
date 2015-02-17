BLUEPRINT_BUILD_COMMAND = './autotune-build'

# A snapshot of a git repo
class Snapshot
  include ShellUtils

  # Create a new snapshot
  def self.create(source, working_dir, env = {})
    r = new(working_dir, env)
    r.sync(source)
    r
  end

  def sync(source)
    cmd 'rsync', '-a', "--exclude='.git'", "#{source.working_dir}/", "#{working_dir}/"
  end

  # Run the blueprint build command with the supplied data
  def build(data)
    working_dir do
      cmd BLUEPRINT_BUILD_COMMAND, :stdin_data => data.to_json
    end
  end
end
