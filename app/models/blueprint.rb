require 'fileutils'

BLUEPRINT_CONFIG_FILENAME = 'autotune-config.json'

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
    working_dir_exist? && !installing?
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

  # TODO: figure out where this stuff should go
  def install!
    # Clone the repo
    out, s = Open3.capture2e(
      'git', 'clone', '--recursive', repo_url, working_dir)
    unless s.success?
      logger.error(out)
      update!(:status => 'broken')
      return false
    end

    # Load the blueprint config file into the DB
    Dir.chdir(working_dir) do
      File.open(BLUEPRINT_CONFIG_FILENAME) do |f|
        self.config = ActiveSupport::JSON.decode(f.read)
      end
    end
    # look in the config for stuff like descriptions, sample images, tags
    # TODO: load stuff from config

    # Blueprint is now ready for testing
    self.status = 'testing'
    save!
  rescue JSON::ParserError => exc
    logger.error(exc)
    update!(:status => 'broken')
    false
  end

  def uninstall!
    FileUtils.rm_rf(working_dir) && update!(:status => 'new', :config => nil)
  end

  private

  def defaults
    self.status ||= 'new'
  end
end
