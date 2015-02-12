require 'test_helper'

# Test the builds
class BuildTest < ActiveSupport::TestCase
  test 'creating a build' do
    assert_raises ActiveRecord::RecordInvalid do
      Build.create!(:title => 'new build')
    end

    bp = Blueprint.create!(
      :title => 'new blueprint',
      :repo_url => 'https://github.com/voxmedia/autotune-example-blueprint.git')

    b = Build.create!(:title => 'new build', :blueprint => bp)
    assert_equal b.blueprint, bp
    assert_equal 'new', b.status
  end
end
