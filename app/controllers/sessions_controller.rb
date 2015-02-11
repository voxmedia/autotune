class SessionsController < ApplicationController
  skip_before_action :require_login, :only => [:new, :create, :failure]

  def new; end

  def create
    self.current_user = User.find_or_create_by_auth_hash(omniauth)
    flash[:notice] = "Welcome #{current_user.name}!"
    redirect_to(request.env['omniauth.origin'] || root_path)
  end

  def failure
    redirect_to(
      login_path,
      :alert => "There was a problem logging you in: #{params[:message]}.")
  end

  def destroy
    self.current_user = nil
    redirect_to(login_path, :notice => "You have been logged out.")
  end

  private

  def omniauth
    request.env["omniauth.auth"]
  end
end
