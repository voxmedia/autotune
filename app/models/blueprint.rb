class Blueprint < ActiveRecord::Base
  include Slugged
  has_many :blueprint_tags
  has_many :tags, :through => :blueprint_tags

  validates :title, :repo_url, :presence => true
  validates :status, :inclusion => { :in => %w(new testing ready) }
  after_initialize :defaults

  def defaults
    self.status ||= 'new'
  end
end
