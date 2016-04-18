module Autotune
  # Groups to control access to themes and projects
  class Group < ActiveRecord::Base
    include Slugged

    has_many :themes
    has_and_belongs_to_many :projects
    has_many :group_memberships
    has_many :users, :through => :group_memberships

    validates :slug, :name, :presence => true
    validates :name, :uniqueness => true
    validates :slug,
              :uniqueness => true,
              :format => { :with => /\A[0-9a-z\-_]+\z/ }
  end
end
