# API for blueprints
class BlueprintsController < ApplicationController
  before_action :respond_to_html, :except => [:thumb]

  rescue_from ActiveRecord::UnknownAttributeError do |exc|
    render_error exc.message, :bad_request
  end

  def new; end

  def edit; end

  def index
    if params.key? :status
      @blueprints = Blueprint.where(:status => params[:status])
    else
      @blueprints = Blueprint.all
    end
  end

  def show
    if params[:id] =~ /^\d+$/
      @blueprint = Blueprint.find params[:id]
    else
      @blueprint = Blueprint.find_by_slug params[:id]
    end
  end

  def create
    @blueprint = Blueprint.new
    @blueprint.attributes = request.POST
    if @blueprint.valid?
      @blueprint.save
      @blueprint.update_repo
      render :show, :status => :created
    else
      render_error @blueprint.errors.full_messages.join(', '), :bad_request
    end
  end

  def update
    if params[:id] =~ /^\d+$/
      @blueprint = Blueprint.find params[:id]
    else
      @blueprint = Blueprint.find_by_slug params[:id]
    end
    @blueprint.attributes = request.POST
    if @blueprint.valid?
      @blueprint.save
      render :show, :status => :created
    else
      render_error @blueprint.errors.full_messages.join(', '), :bad_request
    end
  end

  def update_repo
    if params[:id] =~ /^\d+$/
      @blueprint = Blueprint.find params[:id]
    else
      @blueprint = Blueprint.find_by_slug params[:id]
    end
    @blueprint.update_repo
    head :accepted
  end

  def destroy
    if params[:id] =~ /^\d+$/
      @blueprint = Blueprint.find params[:id]
    else
      @blueprint = Blueprint.find_by_slug params[:id]
    end
    if @blueprint.destroy
      head :no_content
      DestroyBlueprintJob.perform_later(@blueprint)
    else
      render_error @blueprint.errors.full_messages.join(', '), :bad_request
    end
  end

  def thumb
    if instance.config.key?('thumbnail') && instance.repo.exist?(instance.config['thumbnail'])
      mime = instance.repo.mime(instance.config['thumbnail'])
      if mime.nil?
        content_type = 'text/plain'
      else
        content_type = mime.content_type
      end
      send_data(
        instance.repo.read(instance.config['thumbnail']),
        :type => content_type,
        :filename => instance.config['thumbnail'],
        :disposition => 'inline')
    else
      head :not_found
    end
  end

  def instance
    if params[:id] =~ /^\d+$/
      @blueprint = Blueprint.find params[:id]
    else
      @blueprint = Blueprint.find_by_slug params[:id]
    end
  end
end
