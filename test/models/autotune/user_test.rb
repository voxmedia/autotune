require 'test_helper'

# test user model
class Autotune::UserTest < ActiveSupport::TestCase
  fixtures 'autotune/users', 'autotune/authorizations', 'autotune/themes'
  test 'creating user' do
    u = Autotune::User.create!(:name => 'foo')
    assert_equal 'foo', u.name

    # Rails can't have an optional field with format validation :(
    #assert_raises ActiveRecord::RecordInvalid do
      #Autotune::User.create!(:name => 'foo', :email => 'foo')
    #end

    u1 = Autotune::User.create!(:name => 'foo', :email => 'foo@example.com')
    u2 = Autotune::User.find_by(:email => 'foo@example.com')
    assert_equal u1.name, 'foo'
    assert_equal u1, u2
    assert_equal u1.id, u2.id
    assert_equal u1.name, u2.name
    assert_equal u1.authorizations.first, u1.authorizations.first
  end

  test 'find or create by auth hash' do
    skip
    u1 = Autotune::User.find_or_create_by_auth_hash(mock_auth[:developer])
    u2 = Autotune::User.find_or_create_by_auth_hash(mock_auth[:developer])
    assert_equal u1, u2
    assert_equal u1.id, u2.id
    assert_equal u1.name, u2.name
    assert_equal u1.authorizations.first, u1.authorizations.first
  end

  test 'find or create by faux auth hash' do
    skip
    u1 = Autotune::User.find_or_create_by_auth_hash(mock_auth[:developer].to_hash)
    u2 = Autotune::User.find_or_create_by_auth_hash(mock_auth[:developer].to_hash)
    assert_equal u1, u2
    assert_equal u1.id, u2.id
    assert_equal u1.name, u2.name
    assert_equal u1.authorizations.first, u1.authorizations.first
  end

  test 'find or create by auth hash with invalid hash' do
    skip
    assert_raises ArgumentError do
      Autotune::User.find_or_create_by_auth_hash({})
    end

    assert_raises ArgumentError do
      Autotune::User.find_or_create_by_auth_hash(:invalid_credentials)
    end
  end

  test 'roles' do
    assert autotune_users(:developer).role? :superuser
    assert autotune_users(:author).role? :author
    assert autotune_users(:editor).role? :editor
    assert autotune_users(:author).role? :author => 'generic'
    assert autotune_users(:editor).role? :editor => 'generic'
    assert !autotune_users(:editor).role?(:superuser)
    assert !autotune_users(:author).role?(:superuser)
    assert autotune_users(:generic_author).role?(:author)
    assert autotune_users(:generic_author).role?(:author => 'generic')
    assert !autotune_users(:generic_author).role?(:editor => 'generic')
    assert autotune_users(:generic_editor).role?(:editor)
    assert autotune_users(:generic_editor).role?(:author => 'generic', :editor => 'generic')
    assert autotune_users(:generic_editor).role?(:editor => 'generic')
  end

  test 'themes' do
    assert_includes autotune_users(:generic_author).author_themes, autotune_themes(:generic)
    assert autotune_users(:generic_author).editor_themes.empty?
    assert_includes autotune_users(:generic_editor).author_themes, autotune_themes(:generic)
    assert_includes autotune_users(:generic_editor).editor_themes, autotune_themes(:generic)
  end
end
