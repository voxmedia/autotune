module Autotune
  # Basic user account
  class User < ActiveRecord::Base
    include Searchable
    has_many :projects
    has_many :group_memberships, -> { includes :group }
    has_many :groups, :through => group_memberships

    serialize :meta, JSON
    serialize :group_memberships, JSON

    default_scope { order('updated_at DESC') }

    search_fields :email, :name

    validates :api_key, :presence => true, :uniqueness => true
    after_initialize :defaults

    has_many :authorizations, :dependent => :destroy do
      def create_from_auth_hash(auth_hash)
        Authorization.validate_auth_hash(auth_hash)
        create(auth_hash.to_hash)
      end

      def create_from_auth_hash!(auth_hash)
        Authorization.validate_auth_hash(auth_hash)
        create!(auth_hash.to_hash)
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
      return false if !verified? || group_memberships.nil?

      if args.any?
        group_memberships.exists?(:role => args.flatten)
      else
        kwargs.reduce(false) do |a, (k, v)|
          group = Group.find_by_slug v
          a ||
            (!group.nil? &&
              group_memberships.exists?(
                :role => k.to_s,
                :group_id => group.id
              )
            )
        end
      end
    end

    # Return an array list of themes that this user is permitted to use in a project
    def author_themes
      return [] if !verified? || group_memberships.nil?
      Theme.where('(group_id IN (?))',
                  group_memberships.pluck(:group_id))
    end

    # Return an array list of themes that this user is permitted to modify
    def designer_themes
      return [] if !verified? || group_memberships.nil?
      Theme.where('(group_id IN (?))',
                  group_memberships.with_design_access.pluck(:group_id))
    end

    # Return an array list of groups that this user has at least editor privileges for
    def editor_groups
      return if group_memberships.nil?

      groups.merge(group_memberships.with_editor_access)
    end

    # Return an array list of groups that this user has at least designer privileges for
    def designer_groups
      return if group_memberships.nil?

      groups.merge(group_memberships.with_design_access)
    end

    # Return an array list of groups that this user has access to
    def author_groups
      return if group_memberships.nil?

      groups.merge(group_memberships)
    end

    def preferred_auth
      authorizations.preferred
    end

    def roles
      meta['roles'] || preferred_auth.roles
    end

    def verified?
      (roles.is_a?(Array) || roles.is_a?(Hash)) && roles.any?
    end

    def update_membership
      # remove user's memberships if no roles are provided
      if roles.nil?
        user.group_memberships.delete
        return
      end

      # Global role assignment
      # If roles is an array , assign the highest privileges to all groups
      if roles.is_a?(Array) && roles.any?
        role_to_assign = GroupMembership.get_best_role(roles)
        if role_to_assign.nil?
          group_memberships.delete
          return
        end
      # assign global superuser role if the user has superuser role for anything
      elsif roles.is_a?(Hash) && !roles[:superuser].nil?
        role_to_assign = :superuser
      end

      unless role_to_assign.nil?
        # create a generic group if for some reason no group exists
        if Group.all.empty?
          group = Group.create!(:name => 'generic')
          Theme.add_default_theme_for_group(group)
        end
        Group.all.find_each do |g|
          membership = group_memberships.find_or_create_by(:group => g)
          membership.role = role_to_assign.to_s
          membership.save!
        end
        return
      end

      # handle the case where it is a hash but not superuser
      if roles.is_a?(Hash) && roles.any?
        stale_ids = group_memberships.pluck(:id)
        [:author, :editor, :designer].each do |r|
          next if roles[r.to_s].nil?
          roles[r.to_s].each do |g|
            group = Group.find_or_create_by(:name => g)
            group.save
            Theme.add_default_theme_for_group(group)
            membership = group_memberships.find_or_create_by(:group => group)
            membership.role = r.to_s
            membership.save!
            stale_ids.delete(membership.id)
          end
        end
      end
      # delete all memberships that weren't updated
      group_memberships.where('id in ?', stale_ids).delete_all unless stale_ids.empty?
      save
    end

    private

    def defaults
      self.api_key ||= User.generate_api_key
      self.meta ||= {}
    end
  end
end
