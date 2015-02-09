require 'test_helper'

class BlueprintTagTest < ActiveSupport::TestCase
  test 'blueprints can have tags' do
    t = Tag.create!(:title => 'My tag')
    assert_equal t.slug, 'my-tag'

    b = Blueprint.create!(
      :title => 'new blueprint',
      :repo_url => 'https://github.com/voxmedia/autotune-example-blueprint.git',
      :tags => [t])
    assert_equal b.tags.first, t
  end
end
