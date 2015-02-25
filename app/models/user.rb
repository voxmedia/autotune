# Basic user account
class User < ActiveRecord::Base
  has_many :authorizations
  serialize :meta, Hash

  validates :name, :email, :api_key, :presence => true
  validates :email, :api_key, :uniqueness => true
  validates :email,
            :uniqueness => { :case_sensitive => false },
            :format => { :with => /@/ }
  after_initialize :defaults

  def self.generate_api_key
    range = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
    20.times.map { range[rand(61)] }.join('')
  end

  def self.find_or_create_by_auth_hash(auth_hash)
    find_by_auth_hash(auth_hash) || create_from_auth_hash(auth_hash)
  end

  def self.create_from_auth_hash(auth_hash)
    verify_auth_hash(auth_hash)
    a = Authorization.new(
      auth_hash.is_a?(OmniAuth::AuthHash) ? auth_hash.to_hash : auth_hash)
    a.user = User
      .create_with(:name => auth_hash['info']['name'])
      .find_or_create_by!(:email => auth_hash['info']['email'])
    a.save!
    a.user
  end

  def self.find_by_auth_hash(auth_hash)
    verify_auth_hash(auth_hash)
    a = Authorization.where(
      :provider => auth_hash['provider'],
      :uid => auth_hash['uid']).first

    a.user unless a.nil?
  end

  def self.find_by_api_key(api_key)
    find_by(:api_key => api_key)
  end

  def self.verify_auth_hash(auth_hash)
    raise ArgumentError, 'Auth hash is empty or nil' if auth_hash.nil? || auth_hash.empty?
    raise ArgumentError, 'Auth hash is not a hash' unless auth_hash.is_a?(Hash)
    raise ArgumentError, "Missing 'info' in auth hash" unless auth_hash.key?('info')
  end

  private

  def defaults
    self.api_key ||= User.generate_api_key
  end
end
