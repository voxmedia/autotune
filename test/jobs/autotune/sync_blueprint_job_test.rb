require 'test_helper'

MASTER_HEAD = 'e03176388c7d1f6dd91a5856b0197d80168a57a2'
TEST_HEAD = 'b36b32c97fa027d4f86b64559377d9dd47a3530b'
WITH_SUBMOD = '4d3dc6432b464f4d42b0e30b891824ad72ef6abb'
NO_SUBMOD = 'fdb4b18d01461574f68cbd763731499af2da561d'

# Test the install blueprint job
class Autotune::SyncBlueprintJobTest < ActiveJob::TestCase
  fixtures 'autotune/blueprints', 'autotune/projects', 'autotune/themes'
  test 'install blueprint' do
    bp = autotune_blueprints(:example)
    # the fixture has 5 themes
    assert_equal 5, bp.themes.count

    assert_performed_jobs 0

    perform_enqueued_jobs do
      Autotune::SyncBlueprintJob.perform_later bp, :status => 'testing'
    end

    assert_performed_jobs 1

    bp.reload

    assert bp.installed?, 'Blueprint should be installed'
    assert_equal 'testing', bp.status
    # only `generic` and `vox` themes are enabled for the test suite
    # the sync should have reset all the themes to just the one available
    assert_equal 2, bp.themes.count

    assert_equal '/media/example-blueprint/thumbnail.jpg', bp.thumb_url
  end

  test 'blueprint versioning' do
    bp = autotune_blueprints(:example)
    bp.update(:version => NO_SUBMOD)

    assert_performed_jobs 1 do
      Autotune::SyncBlueprintJob.perform_later bp, :status => 'testing'
    end

    bp.reload

    repo = WorkDir.repo(bp.working_dir,
                        Rails.configuration.autotune.build_environment)

    assert_equal NO_SUBMOD, bp.version,
                 'Repo should be checked out to the correct version'

    refute repo.exist?('submodule/test.rb'),
           'Should not have a submodule with a test.rb file'

    refute repo.exist?('submodule/testfile'),
           'Should not have submodule testfile'

    bp.update(:version => WITH_SUBMOD)

    assert_performed_jobs 1 do
      Autotune::SyncBlueprintJob.perform_later bp, :status => 'testing'
    end

    bp.reload

    assert_equal WITH_SUBMOD, bp.version,
                 'Repo should be checked out to the correct version'

    assert repo.exist?('submodule/test.rb'),
           'Should have a submodule with a test.rb file'

    refute repo.exist?('submodule/testfile'),
           'Should not have submodule testfile'

    assert_performed_jobs 1 do
      Autotune::SyncBlueprintJob.perform_later bp,
        :status => 'testing', :update => 'true'
    end

    bp.reload

    assert_equal MASTER_HEAD, bp.version,
                 'Repo should be checked out to the correct version'

    assert repo.exist?('submodule/test.rb'),
           'Should have a submodule with a test.rb file'

    assert repo.exist?('submodule/testfile'),
           'Should have submodule testfile'
  end

  test 'blueprint branches' do
    bp = autotune_blueprints(:example)
    bp.update(:repo_url => "#{bp.repo_url}#test")

    assert_performed_jobs 1 do
      Autotune::SyncBlueprintJob.perform_later bp, :status => 'testing'
    end

    bp.reload

    repo = WorkDir.repo(bp.working_dir,
                        Rails.configuration.autotune.build_environment)

    assert_equal TEST_HEAD, repo.version,
                 'Repo should be checked out to the correct version'

    assert_equal TEST_HEAD, bp.version,
                 'Model should have correct version saved'

    assert repo.exist?('test.rb'),
           'Should have a test.rb file'

    assert repo.exist?('testfile'),
           'Should have testfile'

    refute repo.exist?('submodule/test.rb'),
           'Should not have a submodule with a test.rb file'

    refute repo.exist?('submodule/testfile'),
           'Should not have submodule testfile'
  end

  test 'blueprint change branches' do
    bp = autotune_blueprints(:example)

    assert_performed_jobs 1 do
      Autotune::SyncBlueprintJob.perform_later bp, :status => 'testing'
    end

    bp.reload

    repo = WorkDir.repo(bp.working_dir,
                        Rails.configuration.autotune.build_environment)

    assert_equal MASTER_HEAD, repo.version,
                 'Repo should be checked out to the correct version'

    assert_equal MASTER_HEAD, bp.version,
                 'Model should have correct version saved'

    assert repo.exist?('test.rb'),
           'Should have a test.rb file'

    refute repo.exist?('testfile'),
           'Should not have testfile'

    assert repo.exist?('submodule/test.rb'),
           'Should have a submodule with a test.rb file'

    assert repo.exist?('submodule/testfile'),
           'Should have submodule testfile'

    bp.update(:repo_url => "#{bp.repo_url}#test")

    assert_performed_jobs 1 do
      Autotune::SyncBlueprintJob.perform_later bp, :status => 'testing'
    end

    bp.reload

    assert_equal TEST_HEAD, repo.version,
                 'Repo should be checked out to the correct version'

    assert_equal TEST_HEAD, bp.version,
                 'Model should have correct version saved'

    assert repo.exist?('test.rb'),
           'Should have a test.rb file'

    assert repo.exist?('testfile'),
           'Should have testfile'

    refute repo.exist?('submodule/test.rb'),
           'Should not have a submodule with a test.rb file'

    refute repo.exist?('submodule/testfile'),
           'Should not have submodule testfile'
  end

  test 'blueprint versioning with branch' do
    bp = autotune_blueprints(:example)
    bp.update(
      :repo_url => "#{bp.repo_url}#master", :version => NO_SUBMOD)

    assert_performed_jobs 1 do
      Autotune::SyncBlueprintJob.perform_later bp, :status => 'testing'
    end

    bp.reload

    repo = WorkDir.repo(bp.working_dir,
                        Rails.configuration.autotune.build_environment)

    assert_equal NO_SUBMOD, bp.version,
                 'Repo should be checked out to the correct version'

    refute repo.exist?('submodule/test.rb'),
           'Should not have a submodule with a test.rb file'

    refute repo.exist?('submodule/testfile'),
           'Should not have submodule testfile'

    bp.update(:version => WITH_SUBMOD)

    assert_performed_jobs 1 do
      Autotune::SyncBlueprintJob.perform_later bp, :status => 'testing'
    end

    bp.reload

    assert_equal WITH_SUBMOD, bp.version,
                 'Repo should be checked out to the correct version'

    assert repo.exist?('submodule/test.rb'),
           'Should have a submodule with a test.rb file'

    refute repo.exist?('submodule/testfile'),
           'Should not have submodule testfile'

    assert_performed_jobs 1 do
      Autotune::SyncBlueprintJob.perform_later bp,
        :status => 'testing', :update => 'true'
    end

    bp.reload

    assert_equal MASTER_HEAD, bp.version,
                 'Repo should be checked out to the correct version'

    assert repo.exist?('submodule/test.rb'),
           'Should have a submodule with a test.rb file'

    assert repo.exist?('submodule/testfile'),
           'Should have submodule testfile'
  end
end
