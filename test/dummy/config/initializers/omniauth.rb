OmniAuth.config.logger = Rails.logger

Rails.configuration.omniauth_providers = [:developer, :google_oauth2]

Rails.configuration.omniauth_preferred_provider = :developer

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer
  provider :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'],
           :name => 'google_oauth2',
           :prompt => 'select_account',
           :scope => 'email, profile, drive'
end
