require 'autotune/deployer'
require 's3deploy/deployer'

module Autotune
  module Deployers
    # Deploy to s3
    class S3 < Autotune::Deployer
      # Deploy an entire directory
      def deploy(source)
        deployer = S3deploy::Deployer.new(
          :dist_dir => source, :bucket => parts.host,
          :app_path => deploy_path, :logger => logger)
        deployer.deploy!
      end

      # Deploy a single file
      def deploy_file(source, path)
        deployer = S3deploy::Deployer.new(
          :dist_dir => source, :bucket => parts.host,
          :app_path => deploy_path, :logger => logger)
        deployer.deploy_file!(path)
      end
    end
  end
end

Autotune.register_deployer(:s3, Autotune::Deployers::S3)
