module Autotune
  # Basic user account
  class User < ActiveRecord::Base
    include Searchable
    has_many :authorizations, :dependent => :destroy
    has_many :projects
    has_many :group_memberships, -> {includes :group}
    has_many :groups, through: :group_memberships

    serialize :meta, JSON
    serialize :group_memberships, JSON

    validates :api_key, :presence => true, :uniqueness => true
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
      if auth_hash['info'].blank? || auth_hash['info']['email'].blank?
        a.user = User.new
      else
        a.user = User.find_or_initialize_by(:email => auth_hash['info']['email'])
      end
      a.user.attributes = {
        :name => auth_hash['info']['name'],
        :meta => { :roles => roles }
      }
      update_roles(a.user, roles)
      a.user.save!
      a.save!
      a.user
    end

    def self.find_by_auth_hash(auth_hash)
      roles = verify_auth_hash(auth_hash)
      return if roles.nil?
      a = Authorization.find_by(
        :provider => auth_hash['provider'],
        :uid => auth_hash['uid'])
      return if a.nil?

      # if this auth model is missing a user, delete it
      if a.user.nil?
        a.destroy
        return false
      end

      a.update(auth_hash.is_a?(OmniAuth::AuthHash) ? auth_hash.to_hash : auth_hash)

      update_roles a.user, roles
      a.user.save


      a.user
    end

    def self.find_by_api_key(api_key)
      find_by(:api_key => api_key)
    end

    def self.verify_auth_hash(auth_hash)
      if Rails.configuration.autotune.verify_omniauth &&
         Rails.configuration.autotune.verify_omniauth.is_a?(Proc)
        roles = Rails.configuration.autotune.verify_omniauth.call(auth_hash)
        logger.debug "#{auth_hash['nickname']} roles: #{roles}"
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
      return false if group_memberships.nil?

      if args.any?
        group_memberships.exists?(:role => args)
      else
        kwargs.reduce(false) do |a, (k, v)|
          a ||
            group_memberships.exists?(
              :role => k.to_s,
              :group => {:name => v.to_s}
            )
        end
      end
    end

    # Return an array list of themes that this user is permitted to use in a project
    def author_themes
      return [] if group_memberships.nil?
      Theme.where('(group_id IN (?))',
              group_memberships.pluck(:group_id))
    end

    # Return an array list of themes that this user is permitted to modify
    def designer_themes
      return [] if group_memberships.nil?
      Theme.where('(group_id IN (?))',
              group_memberships.with_design_access.pluck(:group_id))
    end

    # Return an array of themes that this user is allowed to edit. Editors can see and change other
    # users' projects. This user will be limited to projects that use these themes.
    # TODO: remove dependency on this
    def editor_themes
      return [] if group_memberships.nil?
      Theme.where('(group_id IN (?))',
              group_memberships.with_editor_access.pluck(:group_id))
    end

    def editor_groups
      return if group_memberships.nil?

      groups.merge(group_memberships.with_editor_access)
    end

    def designer_groups
      return if group_memberships.nil?

      groups.merge(group_memberships.with_design_access)
    end

    def author_groups
      return if group_memberships.nil?

      groups.merge(group_memberships)
    end

    def is_superuser?
        role? :superuser
    end

    private

   # TODO (Kavya) do a security review on this piece
    def self.update_roles(user, roles)
      # make sure the user is saved before trying to update relations
      user.save
      # TODO (Kavya) update roles instead of deleting all
      user.group_memberships.delete
      return if roles.nil?
      # If roles is an array , assign the highest privileges to all groups
      if roles.is_a?(Array) && roles.any?
        best_role = GroupMembership.get_best_role(roles)
        return if best_role.nil?
        Group.all.each do |g|
          user.group_memberships.create(:role => best_role.to_s, :group => g)
        end
        return
      elsif roles.is_a?(Hash) && roles.any?
        [:author, :editor, :designer].each do |r|
          next if roles[r.to_s].nil?
          group = Group.find_or_create_by(:name => roles[r.to_s])
          group.save && user.group_memberships.find_or_create_by(:group => group, :role => r.to_s)
        end
      end
      user.save!
    end

    def defaults
      self.api_key ||= User.generate_api_key
      self.meta    ||= {}
    end
  end
end
