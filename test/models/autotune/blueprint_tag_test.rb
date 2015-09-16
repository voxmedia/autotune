require 'test_helper'

module Autotune
  # test taggy stuff
  class BlueprintTagTest < ActiveSupport::TestCase
    fixtures 'autotune/blueprints'
    setup do
      autotune_blueprints(:example).projects.destroy_all
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

    test 'can delete a blueprint with tags' do
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
