module Autotune
  class GroupMembership < ActiveRecord::Base
    belongs_to :user
    belongs_to :group

    validates :user, :group, :presence => true
    validates :role, :presence => true,
              :inclusion => { :in => Autotune::ROLES }
    validates :group_id, :uniqueness => { :scope => :user_id }

    scope :with_editor_access, -> { where(:role => EDITOR_ROLES) }
    scope :with_design_access, -> { where(:role => DESIGNER_ROLES) }
    scope :with_superuser_access, -> { where(:role => SUPERUSER_ROLES) }

    # Get the highest privileged role from a list of roles
    def self.get_best_role(roles)
      return if roles.nil?
      Autotune::ROLES.reverse.each do |r|
        return r.to_sym if roles.include? r.to_sym
      end
    end

    private
    SUPERUSER_ROLES = [:superuser]
    EDITOR_ROLES = [:editor, :designer, :superuser]
    DESIGNER_ROLES = [:designer, :superuser]
  end
end
