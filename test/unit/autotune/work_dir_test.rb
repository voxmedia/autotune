require 'test_helper'
require 'autoshell'

# Test the WorkDir classes; Repo and Snapshot
class Autotune::WorkDirTest < ActiveSupport::TestCase
  fixtures 'autotune/blueprints'
  test 'setup repo' do
    in_tmpdir do |dir|
      r = Autoshell.new dir

      # working dir is empty, so
      refute r.ruby?, "Shouldn't have ruby"
      refute r.python?, "Shouldn't have python"
      refute r.node?, "Shouldn't have node"
      refute r.git?, "Shouldn't have git"
      refute r.exist?, "Shouldn't exist"
      refute r.dir?, "Shouldn't be a dir"
      assert r.read(Autotune::BLUEPRINT_CONFIG_FILENAME).nil?, 'Should not have a config file'

      # clone git url
      r.clone autotune_blueprints(:example).repo_url

      assert r.ruby?, 'Should have ruby'
      refute r.python?, "Shouldn't have python"
      refute r.node?, "Shouldn't have node"
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
      r = Autoshell.new rdir
      r.clone autotune_blueprints(:example).repo_url
      r.setup_environment

      in_tmpdir do |sdir|
        s = Autoshell.new sdir

        # working dir is empty, so
        refute s.ruby?, "Shouldn't have ruby"
        refute s.python?, "Shouldn't have python"
        refute s.node?, "Shouldn't have node"
        refute s.git?, "Shouldn't have git"
        refute s.exist?, "Shouldn't exist"
        refute s.dir?, "Shouldn't be a dir"
        refute s.environment?, 'Should not have an environment'

        # create a snapshot!
        r.copy_to s.working_dir

        # now should have stuff
        assert s.ruby?, 'Should have ruby'
        refute s.python?, "Shouldn't have python"
        refute s.node?, "Shouldn't have node"
        assert s.git?, 'Should have git'
        assert s.exist?, 'Should exist'
        assert s.dir?, 'Should be a dir'
        assert s.environment?, 'Should have environment'

        assert r.exist?('autotune-build'), 'Should have build script'

        # make sure we can't copy a snapshot twice
        assert_raises Autoshell::CommandError do
          r.copy_to s.working_dir
        end

        s.cd { s.run('./autotune-build', :stdin_data => { :foo => 'bar' }) }

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

  test 'checkout hash' do
    in_tmpdir do |rdir|
      r = Autoshell.new rdir
      r.clone autotune_blueprints(:example).repo_url

      assert_equal MASTER_HEAD, r.version
      assert r.exist?('submodule/testfile'), 'Should have submodule testfile'
      assert r.exist?('submodule/test.rb'), 'Should have submodule test.rb'

      r.commit_hash_for_checkout = WITH_SUBMOD
      r.update
      assert_equal WITH_SUBMOD, r.version
      refute r.exist?('submodule/testfile'), 'Should not have submodule testfile'
      assert r.exist?('submodule/test.rb'), 'Should have submodule test.rb'

      r.commit_hash_for_checkout = NO_SUBMOD
      r.update
      assert_equal NO_SUBMOD, r.version
      refute r.exist?('submodule/testfile'), 'Should not have submodule testfile'
      refute r.exist?('submodule/test.rb'), 'Should not have submodule test.rb'

      r.branch = 'master'
      r.commit_hash_for_checkout = MASTER_HEAD
      r.update
      assert_equal MASTER_HEAD, r.version
      assert r.exist?('submodule/testfile'), 'Should have submodule testfile'
      assert r.exist?('submodule/test.rb'), 'Should have submodule test.rb'
    end
  end

  def in_tmpdir
    path = File.expand_path "#{Dir.tmpdir}/#{Time.now.to_i}#{rand(1000)}/"
    yield path
  ensure
    FileUtils.rm_rf(path) if File.exist?(path)
  end
end
