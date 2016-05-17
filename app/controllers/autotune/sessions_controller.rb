require_dependency 'autotune/application_controller'

module Autotune
  # Handle authentication and user sessions
  class SessionsController < ApplicationController
    skip_before_action :require_login, :only => [:new, :create, :failure]

    def create
      auth = Authorization.find_or_initialize_by_auth_hash(omniauth)

      # If the auth is in the db, make sure its data is up to date
      auth.update_from_auth_hash(omniauth) if auth.persisted?

      # ---------
      # First we're going to check for problems with the authorization and
      # visitor account
      # ---------

      # If the auth is not verified, tell the visitor
      unless auth.verified?
        return render_error(
          'Your account is not authorized. Please contact support.', :bad_request)
      end

      # If the auth is present, but is connected to a different user, we have
      # a problem. Tell the visitor.
      if current_user.present? && auth.persisted? && auth.user != current_user
        return render_error(
          'This account is in use by somebody else. Please contact support.', :bad_request)
      end

      # If visitor is already logged in and trying to log in with the
      # preferred provider, we have a problem. Preferred providers are for
      # primary login and access.
      if current_user.present? && auth.preferred?
        return render_error(
          'This account is used for primary login. You must first log out to use it.', :bad_request)
      end

      # Make sure user is logging in with the preferred method
      if current_user.blank? && !auth.preferred?
        return render_error(
          "You can't use this account to login. You must use a #{Rails.configuration.omniauth_preferred_provider} account.", :bad_request)
      end

      # ---------
      # With most problems ruled out, we can now figure out what to do with
      # the authorization data
      # ---------

      if current_user.present?
        # The visitor is already logged in. They're probably trying to connect
        # a new authorization to this account.

        if auth.new_record?
          # If the auth is not already in the database...
          # check if the current user already has an authorization for this provider
          if current_user.authorizations.find_by_provider(omniauth['provider']).present?
            # if so throw error
            return render_error(
              "Last time you used different account for provider #{omniauth['provider']}. Please try again.", :bad_request)
          end

          auth.user = current_user
          auth.save
        end
      elsif auth.persisted?
        # Visitor is trying to log in and they're already in the database
        # Update group permissions and log the user in!
        auth.user.update_membership
        self.current_user = auth.user
      else
        # First timer. Set them up.
        auth.user = User.new(
          :name => omniauth['info']['name'],
          :email => omniauth['info']['email'],
          :meta => { 'roles' => auth.roles })

        auth.user.save

        # Update user's roles in groups
        auth.user.update_membership
        auth.save

        # Log the user in!
        self.current_user = auth.user
      end

      redirect_to(request.env['omniauth.origin'] || root_path)
    end

    def failure
      render_error("There was a problem logging you in: #{params[:message]}.")
    end

    def destroy
      self.current_user = nil
      render_error('You have been logged out.', :ok)
    end

    def current_user=(u)
      @current_user = u
      if u.nil?
        session.delete(:api_key)
      else
        session[:api_key] = u.api_key
      end
    end

    private

    def omniauth
      request.env['omniauth.auth']
    end
  end
end
