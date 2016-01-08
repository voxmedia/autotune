require_dependency "autotune/application_controller"

module Autotune
  class ThemesController < ApplicationController
    before_action :respond_to_html
    model Theme

    rescue_from ActiveRecord::UnknownAttributeError do |exc|
      render_error exc.message, :bad_request
    end

    before_action :only => [:show, :update, :destroy] do
      unless current_user.role?(:superuser) ||
             current_user.role?(:designer => instance.group.name)
        render_error 'Forbidden', :forbidden
      end
    end

    before_action :only => [:new, :create] do
      unless current_user.role? [:superuser, :designer]
        render_error 'Forbidden', :forbidden
      end
    end

    def new; end

    def edit; end

    def index
      #TODO add search and filter functionality
      @themes = current_user.designer_themes
    end

    def show
      @theme = instance
    end
  end
end
