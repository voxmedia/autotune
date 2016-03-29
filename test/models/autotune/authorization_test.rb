require 'test_helper'

class Autotune::AuthorizationTest < ActiveSupport::TestCase
  fixtures 'autotune/users', 'autotune/authorizations'
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

  test 'creating authorization' do
    autotune_authorizations(:developer).destroy
    assert_raises ActiveRecord::RecordInvalid do
      Autotune::Authorization.create!(@auth_hash)
    end

    a = Autotune::Authorization.new(@auth_hash)
    a.user = Autotune::User
      .create_with(:name => 'test')
      .find_or_create_by!(:email => 'test@example.com')

    assert a.save!
  end

  test 'find by' do
    a = Autotune::Authorization.find_by_auth_hash @auth_hash
    assert_equal autotune_authorizations(:developer), a,
                 'Should match the only authorization we have'
    assert_equal autotune_users(:developer), a.user,
                 'Should match the associated user'

    assert_nothing_raised do
      a = Autotune::Authorization.find_by_auth_hash! @auth_hash
      assert_equal autotune_authorizations(:developer), a,
                   'Should match the only authorization we have'
      assert_equal autotune_users(:developer), a.user,
                   'Should match the associated user'
    end

    a = Autotune::Authorization.find_by_auth_hash(
      'provider' => 'developer', 'uid' => 'foo', 'info' => nil)
    assert_nil a, 'Should find nothing'

    assert_raises ActiveRecord::RecordNotFound do
      Autotune::Authorization.find_by_auth_hash!(
      'provider' => 'developer', 'uid' => 'foo', 'info' => nil)
    end
  end

  test 'create from' do
    user = autotune_users(:developer)

    autotune_authorizations(:developer).destroy
    assert_raises ArgumentError do
      Autotune::Authorization.create_from_auth_hash @auth_hash
    end

    assert_raises ArgumentError do
      Autotune::Authorization.create_from_auth_hash! @auth_hash
    end

    a = Autotune::Authorization.create_from_auth_hash @auth_hash, user
    assert a.valid?
    assert a.persisted?

    a.destroy

    assert_nothing_raised do
      a = Autotune::Authorization.create_from_auth_hash! @auth_hash, user
    end

    a.destroy

    assert user.authorizations.create_from_auth_hash @auth_hash
    user.authorizations.destroy_all

    assert_nothing_raised do
      a = user.authorizations.create_from_auth_hash! @auth_hash
    end
    user.authorizations.destroy_all
  end

  test 'roles' do
    a = autotune_authorizations(:developer)

    assert_equal [:superuser], a.roles,
                 'Should have default role of superuser'
    assert a.verified?, 'Should be verified'

    old_verify = Rails.configuration.autotune.verify_omniauth

    Rails.configuration.autotune.verify_omniauth = lambda do |omniauth|
      nil
    end

    a.reload_roles
    assert_nil a.roles, 'Should nil roles'
    refute a.verified?, 'Should not be verified'

    Rails.configuration.autotune.verify_omniauth = old_verify
  end

  test 'update' do
    skip
  end

  test 'to_auth_hash' do
    a = autotune_authorizations(:developer)
    assert_nothing_raised do
      a.to_auth_hash
    end
  end
end
