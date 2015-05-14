require 'test_helper'
require 'work_dir'

# Test the WorkDir classes; Repo and Snapshot
class Autotune::WorkDirTest < ActionDispatch::IntegrationTest
  test 'setup repo' do
    in_tmpdir do |dir|
      r = WorkDir.repo dir

      # working dir is empty, so
      assert !r.ruby?, "Shouldn't have ruby"
      assert !r.python?, "Shouldn't have python"
      assert !r.node?, "Shouldn't have node"
      assert !r.git?, "Shouldn't have git"
      assert !r.exist?, "Shouldn't exist"
      assert !r.dir?, "Shouldn't be a dir"
      assert r.read(Autotune::BLUEPRINT_CONFIG_FILENAME).nil?, 'Should not have a config file'

      # clone git url
      r.clone repo_url

      assert r.ruby?, 'Should have ruby'
      assert !r.python?, "Shouldn't have python"
      assert !r.node?, "Shouldn't have node"
      assert r.git?, 'Should have git'
      assert r.exist?, 'Should exist'
      assert r.dir?, 'Should be a dir'

      assert r.read(Autotune::BLUEPRINT_CONFIG_FILENAME), 'Should have a config file'

      assert !r.environment?, 'Should not have an environment'

      # setup environment
      r.setup_environment

      assert r.environment?, 'Should have an environment'

      # update repo
      r.update

      # checkout a branch
      r.switch 'test'

      assert r.exist?('testfile'), 'Should have a test file'

      # update bundle
      r.setup_environment
    end
  end

  def in_tmpdir
    path = File.expand_path "#{Dir.tmpdir}/#{Time.now.to_i}#{rand(1000)}/"
    yield path
  ensure
    FileUtils.rm_rf(path) if File.exist?(path)
  end
end
