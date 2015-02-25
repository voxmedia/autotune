# API for blueprints
class BlueprintsController < ApplicationController
  before_action :respond_to_html

  rescue_from ActiveRecord::UnknownAttributeError do |exc|
    render :json => { :error => exc.message }, :status => :bad_request
  end

  def index
    if params.key? :status
      @blueprints = Blueprint.where(:status => params[:status])
    else
      @blueprints = Blueprint.all
    end
  end

  def show
    @blueprint = Blueprint.find params[:id]
  end

  def create
    @blueprint = Blueprint.new
    @blueprint.attributes = request.POST
    if @blueprint.valid?
      @blueprint.save
      render :show, :status => :created
    else
      render :json => { :error => @blueprint.errors.messages }, :status => :bad_request
    end
  end

  def update
    @blueprint = Blueprint.find params[:id]
    @blueprint.attributes = request.POST
    if @blueprint.valid?
      @blueprint.save
      render :show, :status => :created
    else
      render :json => { :error => @blueprint.errors.messages }, :status => :bad_request
    end
  end

  def destroy
    @blueprint = Blueprint.find params[:id]
    @blueprint.destroy
    head :no_content
  end
end
