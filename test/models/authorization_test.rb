require 'test_helper'

class AuthorizationTest < ActiveSupport::TestCase
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
    assert_raises ActiveRecord::RecordInvalid do
      Authorization.create!(@auth_hash)
    end

    a = Authorization.new(@auth_hash)
    a.user = User.create!(@auth_hash['info'])

    assert a.save!
  end
end
