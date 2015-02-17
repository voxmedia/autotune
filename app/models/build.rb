# Blueprints get built
class Build < ActiveRecord::Base
  include Slugged
  serialize :data, Hash
  belongs_to :blueprint

  validates :title, :blueprint, :blueprint_version, :presence => true
  validates :status, :inclusion => { :in => %w(new building built broken) }
  before_validation :defaults

  def working_dir
    File.join(Rails.configuration.builds_dir, slug)
  end

  def working_dir_exist?
    Dir.exist?(working_dir)
  end

  def snapshot
    @_snapshot ||= begin
      if working_dir_exist?
        Snapshot.open working_dir
      else
        Snapshot.create blueprint.repo, working_dir
      end
    end
  end

  private

  def defaults
    self.status ||= 'new'
    self.blueprint_version ||= blueprint.repo.version unless blueprint.nil?
  end
end
