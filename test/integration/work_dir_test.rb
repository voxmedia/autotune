require 'test_helper'
require 'tmpdir'
require 'fileutils'

# Test the WorkDir classes; Repo and Snapshot
class WorkDirTest < ActionDispatch::IntegrationTest
  test 'setup repo' do
    in_tmpdir do |dir|
      r = Repo.new dir

      # working dir is empty, so
      assert !r.ruby?, "Shouldn't have ruby"
      assert !r.python?, "Shouldn't have python"
      assert !r.node?, "Shouldn't have node"
      assert !r.git?, "Shouldn't have git"
      assert !r.exist?, "Shouldn't exist"
      assert !r.dir?, "Shouldn't be a dir"
      assert r.config.nil?, 'Should not have a config file'

      # clone git url
      r.clone repo_url

      assert r.ruby?, 'Should have ruby'
      assert !r.python?, "Shouldn't have python"
      assert !r.node?, "Shouldn't have node"
      assert r.git?, 'Should have git'
      assert r.exist?, 'Should exist'
      assert r.dir?, 'Should be a dir'

      assert r.config, 'Should have a config file'

      assert !r.environment?, 'Should not have an environment'

      # setup environment
      r.setup_environment

      assert r.environment?, 'Should have an environment'
    end
  end

  test 'snapshot' do
    in_tmpdir do |rdir|
      r = Repo.new rdir
      r.clone repo_url
      r.setup_environment

      in_tmpdir do |sdir|
        s = Snapshot.new sdir

        # working dir is empty, so
        assert !s.ruby?, "Shouldn't have ruby"
        assert !s.python?, "Shouldn't have python"
        assert !s.node?, "Shouldn't have node"
        assert !s.git?, "Shouldn't have git"
        assert !s.exist?, "Shouldn't exist"
        assert !s.dir?, "Shouldn't be a dir"

        # create a snapshot!
        s.sync(r)

        # now should have stuff
        assert s.ruby?, 'Should have ruby'
        assert !s.python?, "Shouldn't have python"
        assert !s.node?, "Shouldn't have node"
        assert !s.git?, 'Should not have git'
        assert s.exist?, 'Should exist'
        assert s.dir?, 'Should be a dir'
        assert s.environment?, 'Should have environment'

        s.build(:foo => 'bar')
      end
    end
  end

  def in_tmpdir
    path = File.expand_path "#{Dir.tmpdir}/#{Time.now.to_i}#{rand(1000)}/"
    yield path
  ensure
    FileUtils.rm_rf(path) if File.exist?(path)
  end
end
