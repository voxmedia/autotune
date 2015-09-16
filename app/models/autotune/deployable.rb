module Autotune
  # Handle stuff around having a slug on a model
  module Deployable
    extend ActiveSupport::Concern

    def deployer(target, **kwargs)
      @deployers ||= {}
      key = kwargs.any? ? "#{target}:#{kwargs.to_query}" : target
      @deployers[key] ||=
        Autotune.new_deployer(target.to_sym, self, **kwargs)
    end
  end
end
