require_dependency 'autotune/application_controller'

module Autotune
  # Handle authentication and user sessions
  class SessionsController < ApplicationController
    skip_before_action :require_login, :only => [:new, :create, :failure]

    def create
      self.current_user = User.find_or_create_by_auth_hash(omniauth)
      if current_user
        redirect_to(request.env['omniauth.origin'] || root_path)
      else
        render_error('There was a problem logging you in. Please contact support.')
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
