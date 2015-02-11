# Basic user account
class User < ActiveRecord::Base
  has_many :authorizations
  serialize :meta, Hash

  validates :name, :email, presence: true
  validates :email,
            :uniqueness => { :case_sensitive => false },
            :format => { :with => /\A[^@]+@[^@]+\z/ }

  def self.find_or_create_by_auth_hash(auth_hash)
    find_by_auth_hash(auth_hash) || create_from_auth_hash(auth_hash)
  end

  def self.create_from_auth_hash(auth_hash)
    verify_auth_hash(auth_hash)
    a = Authorization.new(
      auth_hash.is_a?(OmniAuth::AuthHash) ? auth_hash.to_hash : auth_hash)
    a.user = User.create!(
      :name => auth_hash['info']['name'],
      :email => auth_hash['info']['email'])
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

  def self.verify_auth_hash(auth_hash)
    raise ArgumentError, 'Auth hash is empty or nil' if auth_hash.nil? || auth_hash.empty?
    raise ArgumentError, 'Auth hash is not a hash' unless auth_hash.is_a?(Hash)
    raise ArgumentError, "Missing 'info' in auth hash" unless auth_hash.key?('info')
  end
end
