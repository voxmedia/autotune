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

  test 'copy repo' do
    in_tmpdir do |rdir|
      r = WorkDir.repo rdir
      r.clone repo_url
      r.setup_environment

      in_tmpdir do |sdir|
        s = WorkDir.repo sdir

        # working dir is empty, so
        assert !s.ruby?, "Shouldn't have ruby"
        assert !s.python?, "Shouldn't have python"
        assert !s.node?, "Shouldn't have node"
        assert !s.git?, "Shouldn't have git"
        assert !s.exist?, "Shouldn't exist"
        assert !s.dir?, "Shouldn't be a dir"
        assert !s.environment?, 'Should not have an environment'

        # create a snapshot!
        r.copy_to s.working_dir

        # now should have stuff
        assert s.ruby?, 'Should have ruby'
        assert !s.python?, "Shouldn't have python"
        assert !s.node?, "Shouldn't have node"
        assert s.git?, 'Should have git'
        assert s.exist?, 'Should exist'
        assert s.dir?, 'Should be a dir'
        assert s.environment?, 'Should have environment'

        assert r.exist?('autotune-build'), 'Should have build script'

        # make sure we can't copy a snapshot twice
        assert_raises WorkDir::CommandError do
          r.copy_to s.working_dir
        end

        s.working_dir do
          s.cmd('./autotune-build', :stdin_data => { :foo => 'bar' })
        end

        # checkout a different branch in the repo
        s.switch 'test'
        assert s.exist?('testfile'), 'Should have a test file'

        # what happens if i add random crap and switch?
        open(s.expand('foo.bar'), 'w') do |fp|
          fp.write 'baz!!!!'
        end
        assert s.exist?('foo.bar'), 'Should have random crap'

        open(s.expand('testfile'), 'w') do |fp|
          fp.write 'baz!!!!'
        end

        # random crap should get disappeard
        s.switch 'master'
        assert !s.exist?('foo.bar'), 'Random crap should be gone'

        # update the bundle
        FileUtils.rm_rf(s.expand '.bundle')
        assert !s.environment?, 'Should not have an environment'

        s.setup_environment
        assert s.environment?, 'Should have environment'
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
