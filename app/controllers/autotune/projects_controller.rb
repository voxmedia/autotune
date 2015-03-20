require_dependency 'autotune/application_controller'

module Autotune
  # API for projects
  class ProjectsController < ApplicationController
    before_action :respond_to_html

    rescue_from ActiveRecord::UnknownAttributeError do |exc|
      render_error exc.message, :bad_request
    end

    def new; end

    def edit; end

    def index
      query = {}
      query[:status] = params[:status] if params.key? :status
      query[:theme] = params[:theme] if params.key? :theme
      query[:blueprint_id] = params[:blueprint_id] if params.key? :blueprint_id
      if query.empty?
        @projects = Project.all
      else
        @projects = Project.where(query)
      end
    end

    def show
      if params[:id] =~ /^\d+$/
        @project = Project.find params[:id]
      else
        @project = Project.find_by_slug params[:id]
      end
    end

    def create
      data = request.POST.dup
      blueprint = Blueprint.find(data.delete 'blueprint_id')
      @project = Project.new(
        :title => data['title'],
        :slug => data['slug'],
        :blueprint => blueprint,
        :data => data
      )
      if @project.valid?
        @project.save
        @project.build
        render :show, :status => :created
      else
        render_error @project.errors.full_messages.join(', '), :bad_request
      end
    end

    def update
      if params[:id] =~ /^\d+$/
        @project = Project.find params[:id]
      else
        @project = Project.find_by_slug params[:id]
      end
      data = request.POST.dup
      data.delete 'blueprint_id'
      if @project.update(
        :title => data['title'],
        :slug => data['slug'],
        :data => data)
        render :show, :status => :created
      else
        render_error @project.errors.full_messages.join(', '), :bad_request
      end
    end

    def update_snapshot
      if params[:id] =~ /^\d+$/
        @project = Blueprint.find params[:id]
      else
        @project = Blueprint.find_by_slug params[:id]
      end
      @project.update_snapshot
      head :accepted
    end

    def destroy
      if params[:id] =~ /^\d+$/
        @project = Project.find params[:id]
      else
        @project = Project.find_by_slug params[:id]
      end
      if @project.destroy
        head :no_content
        DeleteWorkDirJob.perform_later(@project.working_dir)
      else
        render_error @project.errors.full_messages.join(', '), :bad_request
      end
    end
  end
end
