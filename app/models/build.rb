# Blueprints get built
class Build < ActiveRecord::Base
  include Slugged
  serialize :data, Hash
  belongs_to :blueprint

  validates :title, :blueprint, :presence => true
  validates :status, :inclusion => { :in => %w(new building built broken) }
  after_initialize :defaults

  private

  def defaults
    self.status = 'new'
  end
end
