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
    updated_submod = 'e03176388c7d1f6dd91a5856b0197d80168a57a2'
    with_submod = '4d3dc6432b464f4d42b0e30b891824ad72ef6abb'
    no_submod = 'fdb4b18d01461574f68cbd763731499af2da561d'

    bp = autotune_blueprints(:example)
    bp.update(
      :repo_url => repo_url, :version => no_submod)

    assert_performed_jobs 1 do
      Autotune::SyncBlueprintJob.perform_later bp, :status => 'testing'
    end

    bp.reload

    assert_equal no_submod, bp.version,
                 'Repo should be checked out to the correct version'

    bp.update(:version => with_submod)

    assert_performed_jobs 1 do
      Autotune::SyncBlueprintJob.perform_later bp, :status => 'testing'
    end

    bp.reload

    assert_equal with_submod, bp.version,
                 'Repo should be checked out to the correct version'

    repo = WorkDir.repo(bp.working_dir,
                        Rails.configuration.autotune.build_environment)

    assert repo.exist?('submodule/test.rb'),
           'Should have a submodule with a test.rb file'

    refute repo.exist?('submodule/testfile'),
           'Should not have submodule testfile'

    assert_performed_jobs 1 do
      Autotune::SyncBlueprintJob.perform_later bp,
        :status => 'testing', :update => 'true'
    end

    bp.reload

    assert_equal updated_submod, bp.version,
                 'Repo should be checked out to the correct version'

    assert repo.exist?('submodule/test.rb'),
           'Should have a submodule with a test.rb file'

    assert repo.exist?('submodule/testfile'),
           'Should have submodule testfile'
  end
end
