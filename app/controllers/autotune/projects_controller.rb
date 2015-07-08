require_dependency 'autotune/application_controller'

module Autotune
  # API for projects
  class ProjectsController < ApplicationController
    before_action :respond_to_html
    before_action :require_superuser, :only => [:update_snapshot]
    model Project

    rescue_from ActiveRecord::UnknownAttributeError do |exc|
      render_error exc.message, :bad_request
    end

    before_action :only => [:show, :update, :destroy, :build, :build_and_publish] do
      unless current_user.role?(:superuser) ||
             instance.user == current_user ||
             current_user.role?(:editor => instance.theme.value)
        render_error 'Forbidden', :forbidden
      end
    end

    def new; end

    def edit; end

    def index
      @projects = Project

      # Filter and search query
      query = select_from_get :status
      @projects = @projects.search(params[:search]) if params.key? :search

      if params.key? :theme
        theme = Theme.find_by_value(params[:theme])
        query[:theme_id] = theme.id
      end

      unless current_user.role? :superuser
        if current_user.role? :editor
          @projects = @projects.where(
            '(user_id = ? OR theme_id IN (?))',
            current_user.id, current_user.editor_themes.pluck(:id))
        else
          query[:user_id] = current_user.id
        end
      end

      if query.empty?
        @projects = @projects.all.paginate(:page => params[:page], :per_page => 20)
      else
        @projects = @projects.where(query).paginate(:page => params[:page], :per_page => 20)
      end
    end

    def show
      @project = instance
    end

    def create
      @project = Project.new(:user => current_user)
      @project.attributes = select_from_post :title, :slug, :blueprint_id, :data

      if request.POST.key? 'theme'
        @project.theme = Theme.find_by_value request.POST['theme']

        # is this user allowed to use this theme?
        unless @project.theme.nil? ||
               current_user.author_themes.include?(@project.theme)
          return render_error(
            "You can't use the #{@project.theme.label} theme. Please " \
            'choose another theme or contact support',
            :bad_request)
        end
      end

      # make sure data doesn't contain title, slug or theme
      @project.data.delete('title')
      @project.data.delete('slug')
      @project.data.delete('theme')

      if @project.valid?
        @project.save
        @project.build
        render :show, :status => :created
      else
        render_error @project.errors.full_messages.join(', '), :bad_request
      end
    end

    def update
      @project = instance
      @project.user = current_user if @project.user.nil?
      @project.attributes = select_from_post :title, :slug, :data

      if request.POST.key? 'theme'
        @project.theme = Theme.find_by_value request.POST['theme']

        # is this user allowed to use this theme?
        unless @project.theme.nil? ||
               current_user.author_themes.include?(@project.theme)
          return render_error(
            "You can't use the #{@project.theme.label} theme. Please " \
            'choose another theme or contact support',
            :bad_request)
        end
      end

      # make sure data doesn't contain title, slug or theme
      @project.data.delete('title')
      @project.data.delete('slug')
      @project.data.delete('theme')

      if @project.valid?
        @project.save
        @project.build
        render :show
      else
        render_error @project.errors.full_messages.join(', '), :bad_request
      end
    end

    def update_snapshot
      instance.update_snapshot
      render_accepted
    end

    def build
      instance.build
      render_accepted
    end

    def build_and_publish
      instance.build_and_publish
      render_accepted
    end

    def destroy
      @project = instance
      if @project.destroy
        head :no_content
      else
        render_error @project.errors.full_messages.join(', '), :bad_request
      end
    end
  end
end
