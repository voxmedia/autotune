require 'test_helper'

class Autotune::AuthorizationTest < ActiveSupport::TestCase
  fixtures 'autotune/authorizations'
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
end
