require 'autotune/deployer'

module Autotune
  module Deployers
    # Deploy to the local filesystem
    class File < Autotune::Deployer
      # Deploy an entire directory
      def deploy(source, slug)
        dir = WorkDir.new(source)
        dir.rm(parts.path) if ::File.exist?(parts.path)
        dir.copy_to(::File.join(parts.path, slug))
      end

      # Deploy a single file
      def deploy_file(source, slug, path)
        dir = WorkDir.new(source)
        dir.cp(path, ::File.join(parts.path, slug, path))
      end
    end
  end
end

Autotune.register_deployer(:file, Autotune::Deployers::File)
