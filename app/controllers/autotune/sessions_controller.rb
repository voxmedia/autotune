require_dependency 'autotune/application_controller'

module Autotune
  # Handle authentication and user sessions
  class SessionsController < ApplicationController
    skip_before_action :require_login, :only => [:new, :create, :failure]

    def create
      auth = Authorization.find_by_auth_hash(omniauth)

      if auth.present?
        # If the auth is present, make sure its data is up to date
        auth.update_from_auth_hash(omniauth)
        unless auth.valid?
          # If the auth is not valid, tell the visitor and die
          return render_error(
            'Your account is not authorized. Please contact support.')
        end
      end

      if current_user
        # The visitor is already logged in. They're probably trying to connect
        # a new authorization to this account.

        # Since we are adding an authorization, we must ensure that this new
        # provider isn't the preferred one. Preferred providers are for
        # primary login and access.
        if auth.preferred?
          return render_error(
            'This provider is used for primary login. You cannot add it to an existing account. You must first log out to use it.')
        end

        if auth.present? && auth.user != current_user
          # If the auth is present, but is connected to a different user, we
          # have a problem. Tell the visitor.
          return render_error(
            'This account is in use by somebody else. Please contact support.')
        elsif auth.blank?
          # If the auth is not already in the database...
          # check if the current user already has an authorization for this provider
          if current_user.authorizations.find_by_provider(omniauth['provider']).present?
            # if so throw error
            return render_error(
              "Last time you used different account for provider #{omniauth['provider']}. Please try again.")
          else
            # else add new authorization to current user.
            auth = Authorization.initialize_by_auth_hash(auth_hash)
            unless a.present? && a.verified?
              return render_error(
                'Your account is not authorized. Please contact support.')
            end
            auth.user = current_user
            auth.save
          end
        end

        redirect_to(request.env['omniauth.origin'] || root_path)
      else
        # Visitor is trying to log in...
        if auth.present?
          # Auth is present, visitor has been here before

          # Make sure user is logging in with the preferred method
          unless auth.preferred?
            return render_error(
              "You can't use this account to login. You must use a #{Rails.configuration.omniauth_preferred_provider} account.")
          end

          # Log the user in!
          self.current_user = auth.user
          redirect_to(request.env['omniauth.origin'] || root_path)
        else
          # First timer. Set them up.
          auth = Authorization.initialize_by_auth_hash(auth_hash)
          unless auth.present? && auth.verified?
            return render_error(
              'Your account is not authorized. Please contact support.')
          end

          # Make sure user is logging in with the preferred method
          unless auth.preferred?
            return render_error(
              "You can't use this account to login. You must use a #{Rails.configuration.omniauth_preferred_provider} account.")
          end

          auth.user = User.new(
            :name => auth_hash['info']['name'],
            :email => auth_hash['info']['email'],
            :meta => { 'roles' => auth.roles })

          auth.user.save
          auth.save

          # Log the user in!
          self.current_user = a.user
          redirect_to(request.env['omniauth.origin'] || root_path)
        end
      end
    end

    def failure
      render_error("There was a problem logging you in: #{params[:message]}.")
    end

    def destroy
      self.current_user = nil
      render_error('You have been logged out.', :ok)
    end

    private

    def omniauth
      request.env['omniauth.auth']
    end

  end
end
