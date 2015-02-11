# Look at our environment vars in order to decide which providers to load
if ENV['AUTH_PROVIDERS']
  Rails.configuration.omniauth_providers = ENV['AUTH_PROVIDERS']
    .split(',').map { |p| p.strip.to_sym }
else
  Rails.configuration.omniauth_providers = []
end

# Setup a default preferred method of authentication
if Rails.env.production?
  Rails.configuration.omniauth_preferred_provider = ENV['PREFERRED_AUTH_PROVIDER'].to_sym
else
  Rails.configuration.omniauth_preferred_provider = (
    ENV['PREFERRED_AUTH_PROVIDER'] || :developer).to_sym
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer unless Rails.env.production?

  # Loop over the specified providers and set them up
  Rails.configuration.omniauth_providers.each do |p|
    if p == :github
      provider(p, ENV['GITHUB_KEY'], ENV['GITHUB_SECRET'])
    elsif p == :google_oauth2
      provider(
        p,
        ENV['GOOGLE_CLIENT_ID'],
        ENV['GOOGLE_CLIENT_SECRET'],
        :scope => 'userinfo.email,userinfo.profile',
        :image_aspect_ratio => 'square',
        :image_size => 50)
    end
  end
end
