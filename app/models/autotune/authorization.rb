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

    def self.find_by_auth_hash(auth_hash)
      find_by(:provider => auth_hash['provider'], :uid => auth_hash['uid'])
    end

    def self.find_by_auth_hash!(auth_hash)
      find_by!(:provider => auth_hash['provider'], :uid => auth_hash['uid'])
    end

    def self.create_from_auth_hash(auth_hash, user)
      h = auth_hash.is_a?(OmniAuth::AuthHash) ? auth_hash.to_hash : auth_hash
      create({ :user => user }.update(h))
    end

    def self.create_from_auth_hash!(auth_hash, user)
      h = auth_hash.is_a?(OmniAuth::AuthHash) ? auth_hash.to_hash : auth_hash
      create!({ :user => user }.update(h))
    end

    def self.initialize_from_auth_hash(auth_hash)
      new(auth_hash.is_a?(OmniAuth::AuthHash) ? auth_hash.to_hash : auth_hash)
    end

    def from_auth_hash(auth_hash)
      self.attributes = auth_hash.is_a?(OmniAuth::AuthHash) ? auth_hash.to_hash : auth_hash
    end

    def update_from_auth_hash(auth_hash)
      update(auth_hash.is_a?(OmniAuth::AuthHash) ? auth_hash.to_hash : auth_hash)
    end

    def update_from_auth_hash!(auth_hash)
      update!(auth_hash.is_a?(OmniAuth::AuthHash) ? auth_hash.to_hash : auth_hash)
    end

    def reload_roles
      @roles = self.class.verify_auth_hash(as_json)
      @_roles_cached = true
      @roles
    end

    def roles
      return @roles if @_roles_cached
      reload_roles
    end

    def verified?
      (roles.is_a?(Array) || roles.is_a?(Hash)) && roles.any?
    end

    def preferred?
      provider == Rails.configuration.omniauth_preferred_provider.to_s
    end

    def self.verify_auth_hash(auth_hash)
      raise ArgumentError, 'Auth hash is empty or nil' if auth_hash.nil? || auth_hash.empty?
      raise ArgumentError, 'Auth hash is not a hash' unless auth_hash.is_a?(Hash)
      raise ArgumentError, "Missing 'info' in auth hash" unless auth_hash.key?('info')

      if Rails.configuration.autotune.verify_omniauth.is_a?(Proc)
        roles = Rails.configuration.autotune.verify_omniauth.call(auth_hash)
        logger.debug "#{auth_hash['nickname']} roles: #{roles}"
        return unless (roles.is_a?(Array) || roles.is_a?(Hash)) && roles.any?
        return roles
      else
        return [:superuser]
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
