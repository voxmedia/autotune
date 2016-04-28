require 'test_helper'

# test user model
class Autotune::UserTest < ActiveSupport::TestCase
  fixtures 'autotune/users', 'autotune/authorizations', 'autotune/themes', 'autotune/groups', 'autotune/group_memberships'
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
    assert autotune_users(:author).role? :author => 'group1'
    assert autotune_users(:editor).role? :editor => 'group2'

    assert !autotune_users(:designer).role?(:superuser)
    assert !autotune_users(:editor).role?(:superuser)
    assert !autotune_users(:author).role?(:superuser)

    assert autotune_users(:group2_author).role?(:author)
    assert autotune_users(:group2_author).role?(:author => 'group2')
    assert !autotune_users(:group2_author).role?(:editor => 'group2')
    assert !autotune_users(:group2_author).role?(:author => 'group1')

    assert autotune_users(:group1_editor).role?(:editor)
    assert autotune_users(:group1_editor).role?(:author => 'group1', :editor => 'group1')
    assert autotune_users(:group1_editor).role?(:editor => 'group1')
  end

  test 'themes access' do
    assert_equal autotune_users(:group2_author).author_themes.first, autotune_themes(:theme2)
    assert autotune_users(:group2_author).designer_themes.empty?
    assert_equal autotune_users(:group2_author).author_themes.first, autotune_themes(:theme2)

    assert_equal autotune_users(:group1_editor).author_themes.first, autotune_themes(:theme1)
    assert autotune_users(:group1_editor).designer_themes.empty?

    assert_equal autotune_users(:group1_designer).designer_themes.first, autotune_themes(:theme1)
    assert_equal autotune_users(:group1_designer).author_themes.first, autotune_themes(:theme1)
  end

end
