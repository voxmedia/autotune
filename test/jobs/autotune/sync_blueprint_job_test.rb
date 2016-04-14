require 'test_helper'

# Test the install blueprint job
class Autotune::SyncBlueprintJobTest < ActiveJob::TestCase
  fixtures 'autotune/blueprints', 'autotune/projects', 'autotune/themes'
  test 'install blueprint' do
    bp = autotune_blueprints(:example)

    assert_performed_jobs 0

    perform_enqueued_jobs do
      Autotune::SyncBlueprintJob.perform_later bp, :status => 'testing'
    end

    assert_performed_jobs 1

    bp.reload

    assert bp.installed?, 'Blueprint should be installed'
    assert_equal 'testing', bp.status

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
      Autotune::SyncBlueprintJob.perform_later(
        bp, :update => true, :status => 'testing')
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

  test 'live preview blueprint' do
    bp = autotune_blueprints(:example)
    bp.update(:repo_url => "#{bp.repo_url}#live", :version => MASTER_HEAD)

    repo = WorkDir.repo(bp.working_dir,
                        Rails.configuration.autotune.build_environment)

    assert_performed_jobs 1 do
      Autotune::SyncBlueprintJob.perform_later bp, :status => 'testing'
    end

    assert repo.exist?('autotune-config.json'),
           'Should have autotune config'

    refute repo.exist?('sample.json'),
           'Should not have a sample json'

    bp.reload

    assert_equal MASTER_HEAD, bp.version,
                 'Repo should be checked out to the correct version'

    assert_performed_jobs 1 do
      Autotune::SyncBlueprintJob.perform_later(
        bp, :status => 'testing', :update => true, :build_themes => true)
    end

    assert repo.exist?('autotune-config.json'),
           'Should have autotune config'

    assert repo.exist?('sample.json'),
           'Should have a sample json'

    bp.reload

    assert_equal LIVE_HEAD, bp.version,
                 'Repo should be checked out to the correct version'

    Autotune::Theme.all.each do |theme|
      slug = [bp.version, theme.slug].join('-')
      deployer = Autotune.new_deployer(:media, bp, :extra_slug => slug)

      skip unless deployer.is_a?(Autotune::Deployers::File)

      wd = WorkDir.new deployer.deploy_path

      assert wd.exist?('index.html')
      assert wd.exist?('preview/index.html')
    end
  end

  test 'blueprint versioning with existing files' do
    bp = autotune_blueprints(:example)
    bp.update(:repo_url => "#{bp.repo_url}", :version => MASTER_HEAD2)

    repo = WorkDir.repo(bp.working_dir,
                        Rails.configuration.autotune.build_environment)

    assert_performed_jobs 1 do
      Autotune::SyncBlueprintJob.perform_later bp, :status => 'testing'
    end

    bp.reload

    assert_equal MASTER_HEAD2, repo.version,
                 'Repo should be checked out to the correct version'

    assert_equal MASTER_HEAD2, bp.version,
                 'Model should have correct version saved'

    assert_performed_jobs 1 do
      Autotune::SyncBlueprintJob.perform_later bp, :status => 'testing'
    end

    bp.reload

    assert_equal MASTER_HEAD2, repo.version,
                 'Repo should be checked out to the correct version'

    assert_equal MASTER_HEAD2, bp.version,
                 'Model should have correct version saved'
  end

  test 'update repo' do
    bp = autotune_blueprints(:example)
    bp.update(:repo_url => "#{bp.repo_url}#live", :version => MASTER_HEAD)

    repo = WorkDir.repo(bp.working_dir,
                        Rails.configuration.autotune.build_environment)

    assert_performed_jobs 1 do
      Autotune::SyncBlueprintJob.perform_later bp, :status => 'testing'
    end

    assert repo.exist?('autotune-config.json'),
           'Should have autotune config'

    refute repo.exist?('sample.json'),
           'Should not have a sample json'

    bp.reload

    assert_equal MASTER_HEAD, bp.version,
                 'Repo should be checked out to the correct version'

    assert_performed_jobs 1 do
      bp.update_repo
    end

    assert repo.exist?('autotune-config.json'),
           'Should have autotune config'

    assert repo.exist?('sample.json'),
           'Should have a sample json'

    bp.reload

    assert_equal LIVE_HEAD, bp.version,
                 'Repo should be checked out to the correct version'

    Autotune::Theme.all.each do |theme|
      slug = [bp.version, theme.slug].join('-')
      deployer = Autotune.new_deployer(:media, bp, :extra_slug => slug)

      skip unless deployer.is_a?(Autotune::Deployers::File)

      wd = WorkDir.new deployer.deploy_path

      assert wd.exist?('index.html')
      assert wd.exist?('preview/index.html')
    end
  end
end
