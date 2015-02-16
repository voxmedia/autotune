# Blueprints get built
class Build < ActiveRecord::Base
  include Slugged
  serialize :data, Hash
  belongs_to :blueprint

  validates :title, :blueprint, :blueprint_version, :presence => true
  validates :status, :inclusion => { :in => %w(new building built broken) }
  before_validation :defaults

  private

  def defaults
    self.status ||= 'new'
    self.blueprint_version ||= blueprint.repo.version unless blueprint.nil?
  end
end
