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

      # Filter and search query
      query = {}

      query[:status] = params[:status] if params.key? :status
      query[:group_id] = params[:group] if params.key? :group

      if params.key? :search
        @themes = @themes.search(params[:search], :title)
      end

      @themes = @themes.where(query)

      page = params[:page] || 1
      per_page = params[:per_page] || 15
      @themes = @themes.paginate(:page => page, :per_page => per_page)
      link_str = '<%s>; rel="%s"'
      links = [
        link_str % [
          themes_url(:page => @themes.current_page, :per_page => per_page), 'page'],
        link_str % [
          themes_url(:page => 1, :per_page => per_page), 'first'],
        link_str % [
          themes_url(:page => @themes.total_pages, :per_page => per_page), 'last']
      ]
      if @themes.next_page
        links << link_str % [
          themes_url(:page => @themes.next_page, :per_page => per_page), 'next']
      end
      if @themes.previous_page
        links << link_str % [
          themes_url(:page => @themes.previous_page, :per_page => per_page), 'prev']
      end
      headers['Link'] = links.join(', ')
      headers['X-Total'] = @themes.count
    end

    def show
      @theme = instance
    end

    def create
      @theme = Theme.new
      @theme.attributes = select_from_post :title, :data, :group_id, :slug
      @theme.parent = Theme.get_default_theme_for_group(@theme.group_id)
      if @theme.valid?
        @theme.status = "ready"
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
        @theme.status = "ready"
        render :show
      else
        render_error @theme.errors.full_messages.join(', '), :bad_request
      end
    end

    def reset
      instance.update_data
      render_accepted
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
