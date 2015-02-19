BLUEPRINT_BUILD_COMMAND = './autotune-build'

# A snapshot of a git repo
class Snapshot < WorkDir
  # Rsync files from the source working dir, skip .git
  def sync(source)
    cmd 'rsync', '-a', '--exclude', '.git', "#{source.working_dir}/", "#{working_dir}/"
  end

  # Run the blueprint build command with the supplied data
  def build(data)
    working_dir do
      cmd BLUEPRINT_BUILD_COMMAND, :stdin_data => data.to_json
    end
  end
end
