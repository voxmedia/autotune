require 'test_helper'

class TagTest < ActiveSupport::TestCase
  test 'creating tags' do
    t = Tag.create!(:title => 'My tag')
    assert_equal t.slug, 'my-tag'
  end
end
