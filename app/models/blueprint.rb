require 'uri'
# Blueprint
class Blueprint < ActiveRecord::Base
  include Slugged
  serialize :config, Hash
  has_many :blueprint_tags
  has_many :tags, :through => :blueprint_tags

  validates :title, :repo_url, :presence => true
  validates :status, :inclusion => { :in => %w(new updating testing ready broken) }
  validates :repo_url,
            :format => { :with => URI.regexp }
  after_initialize :defaults

  def working_dir
    File.join(Rails.configuration.blueprints_dir, slug)
  end

  def installed?
    %w(updating testing ready).include? status
  end

  def updating?
    status == 'updating'
  end

  def ready?
    status == 'ready'
  end

  def testing?
    status == 'testing'
  end

  def repo
    @_repo ||= Repo.new working_dir
  end

  def update_repo
    update(:status => 'updating')
    SyncBlueprintJob.perform_later self
  end

  # only call these from a job

  def create_repo
    repo.clone(repo_url)
  end

  def sync_repo
    repo.update
  end

  private

  def defaults
    self.status ||= 'new'
  end
end
