module Autotune
  # Omniauth authorization data
  class Authorization < ActiveRecord::Base
    belongs_to :user
    serialize :info, JSON
    serialize :credentials, JSON
    serialize :extra, JSON

    before_validation :defaults

    validates :user, :provider, :uid, :presence => true
    validates :provider, :uniqueness => { :scope => :user_id }

    # Name of the authentication provider.
    # @return [String] authentication provider name.
    def provider_name
      provider.split('_').first.to_s.titleize
    end

    def from_auth_hash(auth_hash)
      self.attributes = auth_hash.to_hash
    end

    def update_from_auth_hash(auth_hash)
      # update user meta as well
      user.update_roles(roles)
      update(auth_hash.to_hash)
    end

    def update_from_auth_hash!(auth_hash)
      update!(auth_hash.to_hash)
    end

    def reload_roles
      @_roles_cached = true
      @roles = self.class.verify_auth_hash(as_json)
    end

    def roles
      @_roles_cached ? @roles : reload_roles
    end

    def verified?
      (roles.is_a?(Array) || roles.is_a?(Hash)) && roles.any?
    end

    def preferred?
      provider == Rails.configuration.omniauth_preferred_provider.to_s
    end

    def valid_credentials?
      # Make sure we have credentials
      return false if credentials.blank?
      # We're gtg if we have a refresh token
      return true if credentials['refresh_token'].present?
      # If we don't have a refresh token, we must have a token
      return false if credentials['token'].blank?
      # We're gtg if the token does not expire
      return true if credentials['expires'].blank?
      # If the token does expire, make sure it's not expired right now
      return true if credentials['expires_at'].present? &&
                     Time.now.to_i < credentials['expires_at'].to_i

      false
    end

    def to_auth_hash
      OmniAuth::AuthHash.new(as_json)
    end

    class << self
      def find_by_auth_hash(auth_hash)
        validate_auth_hash(auth_hash)
        find_by(:provider => auth_hash['provider'], :uid => auth_hash['uid'])
      end

      def find_by_auth_hash!(auth_hash)
        validate_auth_hash(auth_hash)
        find_by!(:provider => auth_hash['provider'], :uid => auth_hash['uid'])
      end

      def initialize_from_auth_hash(auth_hash)
        validate_auth_hash(auth_hash)
        new(auth_hash.to_hash)
      end

      def find_or_initialize_by_auth_hash(auth_hash)
        find_by_auth_hash(auth_hash) || initialize_from_auth_hash(auth_hash)
      end

      def create_from_auth_hash(auth_hash, user)
        validate_auth_hash(auth_hash)
        create({ :user => user }.update(auth_hash.to_hash))
      end

      def create_from_auth_hash!(auth_hash, user)
        validate_auth_hash(auth_hash)
        create!({ :user => user }.update(auth_hash.to_hash))
      end

      def find_or_create_by_auth_hash(auth_hash)
        find_by_auth_hash(auth_hash) || create_from_auth_hash(auth_hash)
      end

      def validate_auth_hash(auth_hash)
        raise ArgumentError, 'Auth hash is blank' if auth_hash.blank?
        raise ArgumentError, 'Auth hash is not a hash' unless auth_hash.is_a?(Hash)
        %w(provider uid).each do |k|
          raise ArgumentError, "Missing '#{k}' in auth hash" unless auth_hash.key?(k)
        end
      end

      def verify_auth_hash(auth_hash)
        if Rails.configuration.autotune.verify_omniauth.is_a?(Proc)
          roles = Rails.configuration.autotune.verify_omniauth.call(auth_hash)
          logger.debug "#{auth_hash['nickname']} roles: #{roles}"
          return unless (roles.is_a?(Array) || roles.is_a?(Hash)) && roles.any?
          return roles
        else
          return [:superuser]
        end
      end
    end

    private

    def defaults
      self.info ||= {}
      self.credentials ||= {}
      self.extra ||= {}
    end
  end
end
