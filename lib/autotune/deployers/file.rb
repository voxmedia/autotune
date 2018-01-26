require 'autotune/deployer'
require 'autoshell'

module Autotune
  module Deployers
    # Deploy to the local filesystem
    class File < Autotune::Deployer
      # Deploy an entire directory
      def deploy(source)
        dir = Autoshell.new(source)
        dir.rm(deploy_path) if ::File.exist?(deploy_path)
        dir.copy_to(deploy_path, :force => true)
      end

      # Deploy a single file
      def deploy_file(source, path)
        dir = Autoshell.new(source)
        dir.cp(path, [deploy_path, path].join('/'), :force => true)
      end

      # Hook to do stuff after a project is deleted
      def delete!(*)
        dir = Autoshell.new(deploy_path)
        dir.rm if dir.exist?
      end
    end
  end
end

Autotune.register_deployer(:file, Autotune::Deployers::File)
