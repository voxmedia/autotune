require 'test_helper'

module Autotune
  # Tesing the Blueprint model
  class BlueprintTest < ActiveSupport::TestCase
    fixtures 'autotune/blueprints'

    test 'creating blueprints' do
      autotune_blueprints(:example).destroy
      assert_raises ActiveRecord::RecordInvalid do
        Blueprint.create!(:title => 'new blueprint')
      end
      b = Blueprint.create!(
        :title => 'new blueprint',
        :repo_url => repo_url)
      assert_equal b.status, 'new'
      assert_equal b.slug, 'new-blueprint'
    end

    test 'search blueprints' do
      assert_equal 1, Blueprint.search('Example').count
      assert_equal 0, Blueprint.search('foo').count
    end

    test "that slugs don't change" do
      autotune_blueprints(:example).destroy
      b = Blueprint.create!(
        :title => 'new blueprint',
        :repo_url => repo_url)
      assert_equal b.slug, 'new-blueprint'
      b.title = 'updated blueprint'
      b.save!
      b.reload
      assert_equal b.slug, 'new-blueprint'
    end

    test 'custom slugs' do
      autotune_blueprints(:example).destroy
      b = Blueprint.create!(
        :title => 'new blueprint',
        :repo_url => repo_url,
        :slug => 'foobar')
      assert_equal b.slug, 'foobar'
    end

    test 'automatic slugs are unique' do
      autotune_blueprints(:example).destroy
      b = Blueprint.create!(
        :title => 'new blueprint',
        :repo_url => repo_url)
      assert_equal b.slug, 'new-blueprint'

      b = Blueprint.create!(
        :title => 'new blueprint',
        :repo_url => repo_url + '#1')
      assert_equal b.slug, 'new-blueprint-1'
    end
  end
end
