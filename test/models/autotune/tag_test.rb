require 'test_helper'

class Autotune::TagTest < ActiveSupport::TestCase
  test 'creating tags' do
    t = Autotune::Tag.create!(:title => 'My tag')
    assert_equal t.slug, 'my-tag'
  end
end
