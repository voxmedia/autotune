# Blueprint
class Blueprint < ActiveRecord::Base
  include Slugged
  serialize :config, Hash
  has_many :blueprint_tags
  has_many :tags, :through => :blueprint_tags

  validates :title, :repo_url, :presence => true
  validates :status, :inclusion => { :in => %w(new updating testing ready building broken) }
  after_initialize :defaults

  def working_dir
    File.join(Rails.configuration.blueprints_dir, slug)
  end

  def working_dir_exist?
    Dir.exist?(working_dir)
  end

  def installed?
    %w(updating testing ready building).include? status
  end

  def updating?
    status == 'updating'
  end

  def ready?
    status == 'ready'
  end

  def building?
    status == 'building'
  end

  def repo
    @_repo ||= Repo.new working_dir
  end

  def update_repo
    update(:status => 'updating')
    SyncBlueprintJob.perform_later bp
  end

  private

  def defaults
    self.status ||= 'new'
  end
end
