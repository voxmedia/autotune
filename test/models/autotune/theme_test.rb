require 'test_helper'

class Autotune::ThemeTest < ActiveSupport::TestCase
  fixtures 'autotune/groups', 'autotune/themes', 'autotune/projects'
  test 'creating themes' do
    group = autotune_groups(:group1)
    theme_count = group.themes.count
    t = Autotune::Theme.create!(:title => 'foo', :data => {}, :group => group)
    assert_equal 'foo', t.slug
    assert_equal theme_count + 1, group.themes.count
  end

  test 'add themes to projects' do
    group = autotune_groups(:group1)
    t = Autotune::Theme.create!(:title => 'foo', :data => {}, :group => group)
    p = autotune_projects(:example_one)
    assert_equal p.theme, autotune_themes(:theverge)
    p.theme = t
    assert_equal p.theme, t
  end
end
