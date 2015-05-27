module Autotune
  # Basic user account
  class User < ActiveRecord::Base
    has_many :authorizations, :dependent => :destroy
    has_many :projects
    serialize :meta, JSON

    validates :email, :api_key, :presence => true
    validates :api_key, :email, :uniqueness => true
    validates :email,
              :uniqueness => { :case_sensitive => false },
              :format => { :with => /\A.+@.+\..+\z/ }
    after_initialize :defaults

    def self.generate_api_key
      range = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
      20.times.map { range[rand(61)] }.join('')
    end

    def self.find_or_create_by_auth_hash(auth_hash)
      raise ArgumentError, 'Auth hash is empty or nil' if auth_hash.nil? || auth_hash.empty?
      raise ArgumentError, 'Auth hash is not a hash' unless auth_hash.is_a?(Hash)
      raise ArgumentError, "Missing 'info' in auth hash" unless auth_hash.key?('info')
      find_by_auth_hash(auth_hash) || create_from_auth_hash(auth_hash)
    end

    def self.create_from_auth_hash(auth_hash)
      roles = verify_auth_hash(auth_hash)
      return unless roles.is_a?(Array) && roles.any?
      a = Authorization.new(
        auth_hash.is_a?(OmniAuth::AuthHash) ? auth_hash.to_hash : auth_hash)
      a.user = User
        .create_with(:name => auth_hash['info']['name'], :meta => { 'roles' => roles })
        .find_or_create_by!(:email => auth_hash['info']['email'])
      a.save!
      a.user
    end

    def self.find_by_auth_hash(auth_hash)
      roles = verify_auth_hash(auth_hash)
      return unless roles.is_a?(Array) && roles.any?
      a = Authorization.where(
        :provider => auth_hash['provider'],
        :uid => auth_hash['uid']).first
      return if a.nil?

      if a.user.meta['roles'] != roles
        a.user.meta['roles'] = roles
        a.user.save
      end

      a.user
    end

    def self.find_by_api_key(api_key)
      find_by(:api_key => api_key)
    end

    def self.verify_auth_hash(auth_hash)
      if Rails.configuration.autotune.verify_omniauth &&
         Rails.configuration.autotune.verify_omniauth.is_a?(Proc)
        logger.debug 'verify_auth_hash'
        logger.debug auth_hash
        roles = Rails.configuration.autotune.verify_omniauth.call(auth_hash)
        logger.debug "roles: #{roles}"
        return roles
      else
        return [:superuser]
      end
    end

    def role?(*args)
      return false if meta.nil? || meta['roles'].nil?
      args.reduce(false) { |a, e| a || meta['roles'].include?(e.to_s) }
    end

    private

    def defaults
      self.api_key ||= User.generate_api_key
      self.meta    ||= {}
    end
  end
end
