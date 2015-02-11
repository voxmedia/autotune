require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
    @auth_hash = {
      'provider' => 'developer',
      'uid' => 'test@example.com',
      'info' => {
        'name' => 'test', 'email' => 'test@example.com' },
      'credentials' => {},
      'extra' => {}
    }
  end

  test 'creating user' do
    assert_raises ActiveRecord::RecordInvalid do
      User.create!(:name => 'foo')
    end

    assert_raises ActiveRecord::RecordInvalid do
      User.create!(:name => 'foo', :email => 'foo')
    end

    u1 = User.create!(:name => 'foo', :email => 'foo@example.com')
    u2 = User.find_by(:name => 'foo')
    assert_equal u1.name, 'foo'
    assert_equal u1, u2
    assert_equal u1.id, u2.id
    assert_equal u1.name, u2.name
    assert_equal u1.authorizations.first, u1.authorizations.first
  end

  test 'find or create by auth hash' do
    u1 = User.find_or_create_by_auth_hash(@auth_hash)
    u2 = User.find_or_create_by_auth_hash(@auth_hash)
    assert_equal u1, u2
    assert_equal u1.id, u2.id
    assert_equal u1.name, u2.name
    assert_equal u1.authorizations.first, u1.authorizations.first
  end
end
