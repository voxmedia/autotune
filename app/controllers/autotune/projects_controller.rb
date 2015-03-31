require_dependency 'autotune/application_controller'

module Autotune
  # API for projects
  class ProjectsController < ApplicationController
    before_action :respond_to_html
    model Project

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
      @project = instance
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
      @project = instance
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
      instance.update_snapshot
      head :accepted
    end

    def build
      instance.build
      head :accepted
    end

    def build_and_publish
      instance.build_and_publish
      head :accepted
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
