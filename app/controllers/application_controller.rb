class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  #protect_from_forgery with: :exception

  before_action :require_login

  helper_method :current_user, :signed_in?, :omniauth_path

  def index
    pp current_user
  end

  protected

  def append_info_to_payload(payload)
    super
    payload[:host] = request.host
    payload[:remote_ip] = request.remote_ip
  end

  def omniauth_path(provider, origin = nil)
    path = "/auth/#{provider}"
    path += "?origin=#{CGI.escape(origin)}" unless origin.blank?
    path
  end

  def current_user
    if session[:current_user_id].present?
      User.find_by_id(session[:current_user_id])
    else
      nil
    end
  end

  def current_user=(u)
    if u.nil?
      session.delete(:current_user_id)
    else
      session[:current_user_id] = u.id
    end
  end

  def signed_in?
    current_user.present?
  end

  private

  def require_login
    redirect_to omniauth_path(:developer, request.fullpath) unless signed_in?
  end
end
