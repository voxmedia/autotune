require_dependency 'autotune/application_controller'

module Autotune
  # API for projects
  class ProjectsController < ApplicationController
    before_action :respond_to_html
    before_action :require_superuser, :only => [:update_snapshot]
    before_action :require_authorization,
                  :only => [:show, :update, :destroy, :build, :build_and_publish]
    model Project

    rescue_from ActiveRecord::UnknownAttributeError do |exc|
      render_error exc.message, :bad_request
    end

    def new; end

    def edit; end

    def index
      @projects = Project
      query = select_from_get :status, :theme_id, :blueprint_id
      query['user'] = current_user unless current_user.role? :editor, :superuser
      @projects = @projects.search(params[:search]) if params.key? :search
      if query.empty?
        @projects = @projects.all
      else
        @projects = @projects.where(query)
      end

      # include the current name of the blueprint
      respond_to do |format|
        format.json do
          render :json => @projects.to_json(:methods => [:blueprint_title, :created_by])
        end
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

    def require_authorization
      return if instance.user == current_user
      require_role :superuser, :editor
    end
  end
end
