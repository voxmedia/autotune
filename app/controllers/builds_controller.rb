# API for builds
class BuildsController < ApplicationController
  before_action :respond_to_html

  rescue_from ActiveRecord::UnknownAttributeError do |exc|
    render_error exc.message, :bad_request
  end

  def index
    if params.key? :status
      @builds = Build.where(:status => params[:status])
    else
      @builds = Build.all
    end
  end

  def show
    @build = Build.find params[:id]
  end

  def create
    @build = Build.new
    @build.attributes = request.POST
    if @build.valid?
      @build.save
      render :show, :status => :created
    else
      render_error @build.errors.messages, :bad_request
    end
  end

  def update
    @build = Build.find params[:id]
    @build.attributes = request.POST
    if @build.valid?
      @build.save
      render :show, :status => :created
    else
      render_error @build.errors.messages, :bad_request
    end
  end

  def destroy
    @build = Build.find params[:id]
    @build.destroy
    head :no_content
  end
end

