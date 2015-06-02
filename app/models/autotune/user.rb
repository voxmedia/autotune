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
      return if roles.nil?
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
      return if roles.nil?
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
        return unless (roles.is_a?(Array) || roles.is_a?(Hash)) && roles.any?
        return roles
      else
        return [:superuser]
      end
    end

    # Check that the user has a role, optionally check that user has role for
    # a specific theme.
    #   user.role?(:superuser) # is this user a super user?
    #   user.role?(:author, :editor) # is this user an author or editor?
    #   user.role?(:author => :sbnation) # is this user an author who can use sbnation themes?
    #   # is this user an editor who can use vox or theverge themes?
    #   user.role?(:editor => :vox, :editor => :theverge)
    def role?(*args, **kwargs)
      return false if meta.nil? || meta['roles'].nil?
      if args.any?
        args.reduce(false) { |a, e| a || meta['roles'].include?(e.to_s) }
      else
        kwargs.reduce(false) do |a, (k, v)|
          a ||
            (meta['roles'].is_a?(Array) && meta['roles'].include?(k.to_s)) ||
            (meta['roles'].include?(k.to_s) && meta['roles'][k.to_s].include?(v.to_s))
        end
      end
    end

    # Return an array list of themes that this user is permitted to use in a project
    def author_themes
      return [] if meta.nil? || meta['roles'].nil?
      # if this is a superuser, return all available themes
      # if we only have an array of roles, all themes are available
      if role?(:superuser) || (meta['roles'].is_a?(Array) && role?(:author, :editor))
        themes = Rails.configuration.autotune.themes.keys
      else
        # otherwise get all the themes for all the roles and make an array
        themes = []
        [:author, :editor, :superuser].each do |r|
          themes += meta['roles'][r.to_s] if meta['roles'][r.to_s]
        end
        themes.uniq!
      end
      # return an array list of theme objects
      Theme.where :value => themes
    end

    # Return an array of themes that this user is allowed to edit. Editors can see and change other
    # users' projects. This user will be limited to projects that use these themes.
    def editor_themes
      return [] if meta.nil? || meta['roles'].nil?
      # authors can't edit other projects
      return [] unless role?(:editor, :superuser)
      # if we only have an array, superusers and editors can edit all themes
      # also, superusers can always edit all the themes, even if we have a hash of roles
      if meta['roles'].is_a?(Array) || role?(:superuser)
        themes = Rails.configuration.autotune.themes.keys
      else
        # otherwise get all the themes for editor
        themes = meta['roles']['editor']
      end
      # return an array list of theme objects
      Theme.where :value => themes
    end

    private

    def defaults
      self.api_key ||= User.generate_api_key
      self.meta    ||= {}
    end
  end
end
