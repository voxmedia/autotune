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

    def provider_name
      provider.split('_').first.to_s.titleize
    end

    private

    def defaults
      # def request_token_from_google
      #   url = URI("https://accounts.google.com/o/oauth2/token")
      #   Net::HTTP.post_form(url, self.to_params)
      # end
      # puts 'self.creds'
      # pp self.credentials
      # puts 'in creds', Time.parse(self.credentials['expires_at'])
      # puts 'now', Time.now
      self.info ||= {}
      self.credentials ||= {}
      self.extra ||= {}
    end
  end
end
