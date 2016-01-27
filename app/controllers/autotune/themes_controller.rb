require_dependency "autotune/application_controller"

module Autotune
  class ThemesController < ApplicationController
    before_action :respond_to_html
    model Theme

    rescue_from ActiveRecord::UnknownAttributeError do |exc|
      render_error exc.message, :bad_request
    end

    before_action :only => [:show, :create, :update, :destroy] do
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

    def create
      @theme = Theme.new
      @theme.attributes = select_from_post :title, :data, :group_id, :slug
      @theme.parent = Theme.get_default_theme_for_group(@theme.group_id)
      if @theme.valid?
        @theme.save
        render :show, :status => :created
      else
        render_error @theme.errors.full_messages.join(', '), :bad_request
      end
    end

    def update
      @theme = instance
      @theme.attributes = select_from_post :title, :data
      if @theme.valid?
        @theme.save
        render :show
      else
        render_error @theme.errors.full_messages.join(', '), :bad_request
      end
    end

    def destroy
      @theme = instance
      if @theme.parent.nil?
        render_error(
          'Default themes cannot be deleted',
          :bad_request)
      elsif @theme.projects.count > 0
        render_error(
          'This theme is in use. You must delete the projects which use this theme.',
          :bad_request)
      elsif @theme.destroy
        head :no_content
      else
        render_error @theme.errors.full_messages.join(', '), :bad_request
      end
    end
  end
end
