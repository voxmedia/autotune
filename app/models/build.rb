# Blueprints get built
class Build < ActiveRecord::Base
  include Slugged
  serialize :data, Hash
  belongs_to :blueprint

  validates :title, :blueprint, :blueprint_version, :presence => true
  validates :status, :inclusion => { :in => %w(new updating updated building built broken) }
  before_validation :defaults

  def working_dir
    File.join(Rails.configuration.builds_dir, slug)
  end

  def working_dir_exist?
    Dir.exist?(working_dir)
  end

  def snapshot
    @_snapshot ||= Snapshot.new working_dir
  end

  def update_snapshot
    update(:status => 'updating')
    SyncBuildJob.perform_later(self)
  end

  def build
    update(:status => 'building')
    BuildJob.perform_later(self)
  end

  private

  def defaults
    self.status ||= 'new'
    self.blueprint_version ||= blueprint.repo.version unless blueprint.nil?
  end
end
