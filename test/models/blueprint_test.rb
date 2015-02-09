require 'test_helper'

# Tesing the Blueprint model
class BlueprintTest < ActiveSupport::TestCase
  test 'creating blueprints' do
    assert_raises ActiveRecord::RecordInvalid do
      Blueprint.create!(:title => 'new blueprint')
    end
    b = Blueprint.create!(
      :title => 'new blueprint',
      :repo_url => 'https://github.com/voxmedia/autotune-example-blueprint.git')
    assert_equal b.status, 'new'
    assert_equal b.slug, 'new-blueprint'
  end

  test "that slugs don't change" do
    b = Blueprint.create!(
      :title => 'new blueprint',
      :repo_url => 'https://github.com/voxmedia/autotune-example-blueprint.git')
    assert_equal b.slug, 'new-blueprint'
    b.title = 'updated blueprint'
    b.save!
    b.reload
    assert_equal b.slug, 'new-blueprint'
  end

  test 'custom slugs' do
    b = Blueprint.create!(
      :title => 'new blueprint',
      :repo_url => 'https://github.com/voxmedia/autotune-example-blueprint.git',
      :slug => 'foobar')
    assert_equal b.slug, 'foobar'
  end

  test 'automatic slugs are unique' do
    b = Blueprint.create!(
      :title => 'new blueprint',
      :repo_url => 'https://github.com/voxmedia/autotune-example-blueprint.git')
    assert_equal b.slug, 'new-blueprint'

    b = Blueprint.create!(
      :title => 'new blueprint',
      :repo_url => 'https://github.com/voxmedia/autotune-example-blueprint.git')
    assert_equal b.slug, 'new-blueprint-1'
  end
end
