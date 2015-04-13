require_dependency 'autotune/application_controller'

module Autotune
  # Handle authentication and user sessions
  class SessionsController < ApplicationController
    skip_before_action :require_login, :only => [:new, :create, :failure]

    def create
      self.current_user = User.find_or_create_by_auth_hash(omniauth)
      if current_user
        redirect_to(
          request.env['omniauth.origin'] || root_path,
          :notice => "Welcome #{current_user.name}!")
      else
        redirect_to(login_path, :alert => 'There was a problem logging you in')
      end
    end

    def failure
      redirect_to(
        login_path,
        :alert => "There was a problem logging you in: #{params[:message]}.")
    end

    def destroy
      self.current_user = nil
      redirect_to(login_path, :notice => 'You have been logged out.')
    end

    private

    def omniauth
      request.env['omniauth.auth']
    end
  end
end
