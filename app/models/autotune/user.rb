module Autotune
  # Basic user account
  class User < ActiveRecord::Base
    include Searchable
    has_many :projects
    serialize :meta, JSON

    default_scope { order('updated_at DESC') }

    search_fields :email, :name

    validates :api_key, :presence => true, :uniqueness => true
    after_initialize :defaults

    has_many :authorizations, :dependent => :destroy do
      def create_from_auth_hash(auth_hash)
        create(
          auth_hash.is_a?(OmniAuth::AuthHash) ? auth_hash.to_hash : auth_hash)
      end

      def create_from_auth_hash!(auth_hash)
        create!(
          auth_hash.is_a?(OmniAuth::AuthHash) ? auth_hash.to_hash : auth_hash)
      end

      def preferred
        find_by_provider(Rails.configuration.omniauth_preferred_provider.to_s)
      end
    end

    def self.generate_api_key
      range = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
      20.times.map { range[rand(61)] }.join('')
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
        Autotune::ROLES.each do |r|
          themes += meta['roles'][r] if meta['roles'][r]
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

    def preferred_auth
      authorizations.preferred
    end

    private

    def defaults
      self.api_key ||= User.generate_api_key
      self.meta ||= {}
    end
  end
end
