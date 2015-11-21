require 'autotune/deployer'

module Autotune
  module Deployers
    # Deploy to the local filesystem
    class File < Autotune::Deployer
      # Deploy an entire directory
      def deploy(source)
        dir = WorkDir.new(source)
        dir.rm(deploy_path) if ::File.exist?(deploy_path)
        dir.copy_to(deploy_path)
      end

      # Deploy a single file
      def deploy_file(source, path)
        dir = WorkDir.new(source)
        dir.cp(path, [deploy_path, path].join('/'))
      end

      # Hook to do stuff after a project is deleted
      def delete!
        dir = WorkDir.new(deploy_path)
        dir.destroy if dir.exist?
      end

      # Hook to do stuff after a project is moved (slug changed)
      def move!
        dir = WorkDir.new(old_deploy_path)
        dir.move_to(deploy_path) if dir.exist?
      end
    end
  end
end

Autotune.register_deployer(:file, Autotune::Deployers::File)
