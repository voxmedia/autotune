AUTH_KEY_RE = /API-KEY\s+auth="?([^"]+)"?/

# Base class for all the controllers
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  # protect_from_forgery with: :exception

  before_action :require_login

  helper_method :current_user, :signed_in?, :omniauth_path

  protected

  def omniauth_path(provider, origin = nil)
    path = "/auth/#{provider}"
    path += "?origin=#{CGI.escape(origin)}" unless origin.blank?
    path
  end

  def current_user
    @current_user ||= begin
      if session[:current_user_id].present?
        User.find_by_id(session[:current_user_id])
      elsif request.headers['Authorization'] =~ AUTH_KEY_RE
        api_key_m = AUTH_KEY_RE.match(request.headers['Authorization'])
        User.find_by_api_key(api_key_m[1])
      else
        nil
      end
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
    return true if signed_in?
    respond_to do |format|
      format.html { redirect_to login_path }
      format.json { render_error 'Unauthorized', :unauthorized }
    end
  end

  def respond_to_html
    return unless request.format == 'text/html'
    respond_to do |format|
      format.html { render 'index' }
    end
  end

  def render_error(message, status = :internal_server_error)
    render(
      :error,
      :locals => { :message => message },
      :status => status)
  end

  def login_path
    omniauth_path(Rails.configuration.omniauth_preferred_provider, request.fullpath)
  end
end
