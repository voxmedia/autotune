module Autotune
  # Handle stuff around deploying a model. The model must have the following
  # methods or attributes:
  # - slug
  # - version
  # - config
  # - status
  # - working_dir
  module Deployable
    extend ActiveSupport::Concern

    included do
      after_destroy :delete_deployed_files, :if => :deployed?
      after_save :delete_renamed_files, :if => :deployed?
    end

    # Get a deployer for a specfic target
    # @param [String] Target name: preview, publish, media
    # @param [Hash] Options for the deployer
    # @return [Autotune::Deployer]
    def deployer(target, **kwargs)
      @deployers ||= {}
      key = kwargs.any? ? "#{target}:#{kwargs.to_query}" : target
      @deployers[key] ||=
        Autotune.new_deployer(target.to_sym, **kwargs.dup.update(:project => self, :logger => output_logger))
    end

    # Has this deployable been deployed?
    # @return [Boolean]
    def deployed?
      status != 'new' && version.present?
    end

    # Gets the directory path where built files are stored
    # @return [String] deployment directory path.
    def deploy_dir
      config['deploy_dir'].present? ? config['deploy_dir'] : 'build'
    end

    # Get the full filesystem path to the deployable's built files
    # @return [String] full directory path
    def full_deploy_dir
      File.join(working_dir, deploy_dir)
    end

    # Get the token for a specific provider
    # @param [String] Provider name
    # @return [String] Auth token
    def user_token_for_provider(provider)
      if respond_to?(:user)
        user.authorizations.find_by!(:provider => provider).credentials['token']
      end
    end

    # Get the contents of the logger as a string and reset the logger
    # @return [String] The log
    def dump_output_logger!
      return '' unless defined?(@output_logger) && @output_logger.present?
      @output_logger.close
      str = @output_logger_str.try(:string)
      @output_logger = nil
      str.present? ? str : ''
    end

    def output_logger
      return @output_logger if defined?(@output_logger) && @output_logger.present?

      # Setup a new logger that logs to a string. The resulting log will
      # be saved to the output field of the project.
      @output_logger_str = StringIO.new
      @output_logger = Logger.new @output_logger_str
      @output_logger.formatter = proc do |severity, datetime, _progname, msg|
        "#{datetime.strftime('%b %e %H:%M %Z')}\t#{severity}\t#{msg}\n"
      end

      @output_logger
    end

    private

    def delete_renamed_files
      return if !slug_changed? || slug_was.blank? || slug == slug_was
      old_data = as_json.merge(changed_attributes)
      DeleteDeployedFilesJob.perform_later(
        self.class.name, old_data.to_json, :renamed => true
      )
    end

    def delete_deployed_files
      DeleteDeployedFilesJob.perform_later(self.class.name, to_json)
    end
  end
end
