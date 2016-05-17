require 'test_helper'

module Autotune
  # test taggy stuff
  class BlueprintTagTest < ActiveSupport::TestCase
    fixtures 'autotune/blueprints'

    test 'blueprints can have tags' do
      repo_url = autotune_blueprints(:example).repo_url
      autotune_blueprints(:example).projects.destroy_all
      autotune_blueprints(:example).destroy

      t = Tag.create!(:title => 'My tag')
      assert_equal t.slug, 'my-tag'

      b = Blueprint.create!(
        :title => 'new blueprint',
        :repo_url => repo_url,
        :tags => [t])
      assert_equal b.tags.first, t
    end

    test 'can delete a blueprint with tags' do
      repo_url = autotune_blueprints(:example).repo_url
      autotune_blueprints(:example).projects.destroy_all
      autotune_blueprints(:example).destroy

      t = Tag.create!(:title => 'My tag')
      assert_equal t.slug, 'my-tag'

      b = Blueprint.create!(
        :title => 'new blueprint',
        :repo_url => repo_url,
        :tags => [t])
      assert_equal b.tags.first, t

      assert b.destroy, 'should be able to destroy a blueprint'
    end
  end
end
