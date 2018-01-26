module Autotune
  # Groups to control access to themes and projects
  class Group < ActiveRecord::Base
    include Slugged

    has_many :themes, :dependent => :destroy
    has_many :projects
    has_many :group_memberships, :dependent => :destroy
    has_many :users, :through => :group_memberships

    validates :slug, :name, :presence => true
    validates :name, :uniqueness => true
    validates :slug,
              :uniqueness => true,
              :format => { :with => /\A[0-9a-z\-_]+\z/ }
  end
end
