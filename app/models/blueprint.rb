# Blueprint
class Blueprint < ActiveRecord::Base
  include Slugged
  serialize :config, Hash
  has_many :blueprint_tags
  has_many :tags, :through => :blueprint_tags

  validates :title, :repo_url, :presence => true
  validates :status, :inclusion => { :in => %w(new installing testing ready building broken) }
  after_initialize :defaults

  def working_dir
    File.join(Rails.configuration.working_dir, slug)
  end

  def working_dir_exist?
    Dir.exist?(working_dir)
  end

  def installed?
    %w(testing ready building).include? status
  end

  def installing?
    status == 'installing'
  end

  def ready?
    status == 'ready'
  end

  def building?
    status == 'building'
  end

  def repo
    @_repo ||= begin
      if working_dir_exist?
        Repo.open working_dir
      else
        Repo.clone repo_url, working_dir
      end
    end
  end

  private

  def defaults
    self.status ||= 'new'
  end
end
