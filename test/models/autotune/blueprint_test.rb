require 'test_helper'

module Autotune
  # Tesing the Blueprint model
  class BlueprintTest < ActiveSupport::TestCase
    fixtures 'autotune/blueprints'

    test 'creating blueprints' do
      autotune_blueprints(:example).projects.destroy_all
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
      assert_equal 2, Blueprint.search('Example').count
      assert_equal 1, Blueprint.search('two').count
      assert_equal 0, Blueprint.search('foo').count
    end

    test "that slugs don't change" do
      autotune_blueprints(:example).projects.destroy_all
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
      autotune_blueprints(:example).projects.destroy_all
      autotune_blueprints(:example).destroy
      b = Blueprint.create!(
        :title => 'new blueprint',
        :repo_url => repo_url,
        :slug => 'foobar')
      assert_equal b.slug, 'foobar'
    end

    test 'no duplicate blueprints allowed' do
      bp = autotune_blueprints(:example)

      assert_raises ActiveRecord::RecordInvalid do
        Blueprint.create!(
          :title => 'another new blueprint',
          :repo_url => bp.repo_url)
      end
    end

    test 'automatic slugs are unique' do
      autotune_blueprints(:example).projects.destroy_all
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

    test 'ensure unique slug fails gracefully' do
      autotune_blueprints(:example).projects.destroy_all
      autotune_blueprints(:example).destroy

      assert_raises ActiveRecord::RecordInvalid do
        Blueprint.create!(:repo_url => repo_url)
      end
    end

    test 'slug automatic incrementing' do
      b = autotune_blueprints(:example)
      b.slug = 'new-blueprint'
      b.save!
      b.reload
      assert_equal 'new-blueprint', b.slug

      b = Blueprint.create!(
        :title => 'new blueprint',
        :slug => 'new-blueprint',
        :repo_url => repo_url + '#1')
      assert_equal 'new-blueprint-1', b.slug
      b.slug = 'new-blueprint'
      b.save!
      b.reload
      assert_equal 'new-blueprint-1', b.slug
      b.slug = 'new-blueprint-1'
      b.save!
      b.reload
      assert_equal 'new-blueprint-1', b.slug

      b = Blueprint.create!(
        :title => 'foo bar',
        :slug => 'foo-bar-50',
        :repo_url => repo_url + '#2')
      assert_equal 'foo-bar-50', b.slug

      b = Blueprint.create!(
        :title => 'foo bar',
        :slug => 'foo-bar-50',
        :repo_url => repo_url + '#3')
      assert_equal 'foo-bar-50-1', b.slug

      b = Blueprint.create!(
        :title => 'new blueprint',
        :slug => 'new-blueprint',
        :repo_url => repo_url + '#4')
      assert_equal 'new-blueprint-2', b.slug
      b.slug = 'new-blueprint'
      b.save!
      b.reload
      assert_equal 'new-blueprint-2', b.slug
      b.slug = 'new-blueprint-1'
      b.save!
      b.reload
      assert_equal 'new-blueprint-2', b.slug

      b = Blueprint.create!(
        :title => 'new blueprint',
        :slug => 'new-blueprint-1',
        :repo_url => repo_url + '#5')
      assert_equal 'new-blueprint-3', b.slug

      b = Blueprint.create!(
        :title => 'new blueprint',
        :slug => 'new-blueprint-5',
        :repo_url => repo_url + '#6')
      assert_equal 'new-blueprint-5', b.slug

      b = Blueprint.create!(
        :title => 'new blueprint',
        :slug => 'new-blueprint-5',
        :repo_url => repo_url + '#7')
      assert_equal 'new-blueprint-6', b.slug
    end

    test 'delete a blueprint' do
      autotune_blueprints(:example).projects.destroy_all
      autotune_blueprints(:example).destroy
      b = Blueprint.create!(
        :title => 'new blueprint',
        :repo_url => repo_url)
      assert_equal b.slug, 'new-blueprint'

      assert b.destroy, 'can delete blueprints'
    end

    test 'thumb url' do
      assert_equal(
        '/assets/autotune/at_placeholder.png',
        autotune_blueprints(:example).thumb_url)
    end
  end
end
