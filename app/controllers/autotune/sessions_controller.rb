require_dependency 'autotune/application_controller'

module Autotune
  # Handle authentication and user sessions
  class SessionsController < ApplicationController
    skip_before_action :require_login, :only => [:new, :create, :failure]

    def create
      if current_user
        # things to check:
        # if the current user has matching authorization
        # if current user already has auth from this provider
        # other things
        a = Authorization.find_by(
          :provider => omniauth['provider'],
          :uid => omniauth['uid'])
        if a.present?
          if a.user != current_user
            render_error('Authorization is already in use by another account. Please contact support.')
          end
          # nothing changes
        else
          # check if the current user already has an authorization for this provider
          if current_user.authorizations.find_by(:provider => omniauth['provider'])
            # if so throw error
            render_error("This user account already has an authorization for omniauth provider: #{omniauth['provider']}.")
          else
            # else add new authorization to current user
            current_user.authorizations.create(
              omniauth.is_a?(OmniAuth::AuthHash) ? omniauth.to_hash : omniauth)
          end
        end
        # unless omniauth['provider'] == 'google_oauth2'
        #   redirect_to(request.env['omniauth.origin'] || root_path)
        # end
        redirect_to(request.env['omniauth.origin'] || root_path)
      else
        self.current_user = User.find_or_create_by_auth_hash(omniauth)
        # add a new parameter to find...^^ or do something New
        # if it already exists, add it to the current user - who is currently logged in, not by email
        if current_user
          redirect_to(request.env['omniauth.origin'] || root_path)
        else
          render_error('There was a problem logging you in. Please contact support.')
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
