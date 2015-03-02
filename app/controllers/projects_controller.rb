# API for projects
class ProjectsController < ApplicationController
  before_action :respond_to_html

  rescue_from ActiveRecord::UnknownAttributeError do |exc|
    render_error exc.message, :bad_request
  end

  def new; end

  def edit; end

  def index
    if params.key? :status
      @projects = Project.where(:status => params[:status])
    else
      @projects = Project.all
    end
  end

  def show
    @project = Project.find params[:id]
  end

  def create
    @project = Project.new
    @project.attributes = request.POST
    if @project.valid?
      @project.save
      render :show, :status => :created
    else
      render_error @project.errors.messages, :bad_request
    end
  end

  def update
    @project = Project.find params[:id]
    @project.attributes = request.POST
    if @project.valid?
      @project.save
      render :show, :status => :created
    else
      render_error @project.errors.messages, :bad_request
    end
  end

  def destroy
    @project = Project.find params[:id]
    @project.destroy
    head :no_content
  end
end
