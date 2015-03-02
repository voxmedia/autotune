# Blueprints get built
class Project < ActiveRecord::Base
  include Slugged
  serialize :data, Hash
  belongs_to :blueprint

  validates :title, :blueprint, :blueprint_version, :presence => true
  validates :status, :inclusion => { :in => %w(new updating updated building built broken) }
  before_validation :defaults

  def working_dir
    File.join(Rails.configuration.projects_dir, slug)
  end

  def snapshot
    @snapshot ||= Snapshot.new working_dir
  end

  def update_snapshot
    update(:status => 'updating')
    SyncProjectJob.perform_later(self)
  end

  def project
    update(:status => 'building')
    BuildJob.perform_later(self)
  end

  # only call these from a job

  def sync_snapshot
    snapshot.sync(blueprint.repo)
    update(:blueprint_version => blueprint.repo.version)
  end

  private

  def defaults
    self.status ||= 'new'
    self.blueprint_version ||= blueprint.repo.version unless blueprint.nil?
  end
end
