module Autotune
  # Omniauth authorization data
  class Authorization < ActiveRecord::Base
    belongs_to :user
    serialize :info, JSON
    serialize :credentials, JSON
    serialize :extra, JSON

    before_validation :defaults

    validates :user, :provider, :uid, :presence => true
    validates :provider, :uniqueness => { :scope => :user_id }

    # Name of the authentication provider.
    # @return [String] authentication provider name.
    def provider_name
      provider.split('_').first.to_s.titleize
    end

    private

    def defaults
      self.info ||= {}
      self.credentials ||= {}
      self.extra ||= {}
    end
  end
end
