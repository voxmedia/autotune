require 'test_helper'

class UserTest < ActiveSupport::TestCase
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
    u1 = User.find_or_create_by_auth_hash(mock_auth[:developer])
    u2 = User.find_or_create_by_auth_hash(mock_auth[:developer])
    assert_equal u1, u2
    assert_equal u1.id, u2.id
    assert_equal u1.name, u2.name
    assert_equal u1.authorizations.first, u1.authorizations.first
  end

  test 'find or create by faux auth hash' do
    u1 = User.find_or_create_by_auth_hash(mock_auth[:developer].to_hash)
    u2 = User.find_or_create_by_auth_hash(mock_auth[:developer].to_hash)
    assert_equal u1, u2
    assert_equal u1.id, u2.id
    assert_equal u1.name, u2.name
    assert_equal u1.authorizations.first, u1.authorizations.first
  end

  test 'find or create by auth hash with invalid hash' do
    assert_raises ArgumentError do
      User.find_or_create_by_auth_hash({})
    end

    assert_raises ArgumentError do
      User.find_or_create_by_auth_hash(:invalid_credentials)
    end
  end
end
