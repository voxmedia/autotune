require 'test_helper'

class Autotune::ThemeTest < ActiveSupport::TestCase
  fixtures 'autotune/blueprints', 'autotune/themes', 'autotune/projects'
  test 'creating themes' do
    t = Autotune::Theme.create!(:value => 'foo', :label => 'Foo')
    bp = autotune_blueprints(:example)
    assert_equal 5, bp.themes.count
    bp.themes << t
    assert_equal 6, bp.themes.count
  end

  test 'add themes to projects' do
    t = Autotune::Theme.create!(:value => 'foo', :label => 'Foo')
    p = autotune_projects(:example_one)
    assert_equal p.theme, autotune_themes(:generic)
    p.theme = t
    assert_equal p.theme, t
  end
end
