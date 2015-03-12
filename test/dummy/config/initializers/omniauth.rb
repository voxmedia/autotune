require 'omniauth'
OmniAuth.config.logger = Rails.logger

Rails.configuration.omniauth_providers = [:developer]

Rails.configuration.omniauth_preferred_provider = :developer

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer
end
