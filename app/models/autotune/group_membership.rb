module Autotune
  class GroupMembership < ActiveRecord::Base
    belongs_to :user
    belongs_to :group

    scope :with_author_access, -> { where(:role => USER_ROLES) }
    scope :with_editor_access, -> { where(:role => EDITOR_ROLES) }
    scope :with_design_access, -> { where(:role => DESIGNER_ROLES) }
    scope :with_superuser_access, -> { where(:role => SUPERUSER_ROLES) }

    # Get the highest privileged role from a list of roles
    def self.get_best_role(roles)
      return if roles.nil?
      USER_ROLES.reverse.each do |r|
        return r if roles.include? r
      end
      return
    end

    private
    SUPERUSER_ROLES = [:superuser]
    USER_ROLES = [:author, :editor, :designer, :superuser] #in order of increasing privileges
    EDITOR_ROLES = [:editor, :designer, :superuser]
    DESIGNER_ROLES = [:designer, :superuser]
  end
end
