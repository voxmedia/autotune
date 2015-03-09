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
    if params[:id] =~ /^\d+$/
      @project = Project.find params[:id]
    else
      @project = Project.find_by_slug params[:id]
    end
  end

  def create
    @project = Project.new(
      :title => request.POST['title'],
      :slug => request.POST['slug'],
      :blueprint => Blueprint.find(request.POST['blueprint_id'].to_i),
      :data => request.POST
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
    if @project.update(
      :title => request.POST['title'],
      :slug => request.POST['slug'],
      :data => request.POST)
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
