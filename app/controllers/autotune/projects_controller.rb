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
      query = select_from_get :status, :theme, :blueprint_id
      query['user'] = current_user unless current_user.role? :editor, :superuser
      @projects = @projects.search(params[:search]) if params.key? :search
      if query.empty?
        @projects = @projects.all
      else
        @projects = @projects.where(query)
      end
    end

    def show
      @project = instance
    end

    def create
      @project = Project.new(
        :user => current_user,
        :blueprint => Blueprint.find(request.POST['blueprint_id']))
      @project.attributes = select_from_post :title, :slug, :theme, :data
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
      @project.attributes = select_from_post :title, :slug, :theme, :data
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
