require 'test_helper'

module Autotune
  class BlueprintTagTest < ActiveSupport::TestCase
    fixtures 'autotune/blueprints'
    setup do
      autotune_blueprints(:example).destroy
    end

    test 'blueprints can have tags' do
      t = Tag.create!(:title => 'My tag')
      assert_equal t.slug, 'my-tag'

      b = Blueprint.create!(
        :title => 'new blueprint',
        :repo_url => repo_url,
        :tags => [t])
      assert_equal b.tags.first, t
    end
  end
end
