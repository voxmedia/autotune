require_dependency 'autotune/application_controller'

module Autotune
  # API for blueprints
  class BlueprintsController < ApplicationController
    before_action :respond_to_html, :except => [:thumb]
    model Blueprint

    rescue_from ActiveRecord::UnknownAttributeError do |exc|
      render_error exc.message, :bad_request
    end

    def new; end

    def edit; end

    def index
      @blueprints = Blueprint
      query = {}
      query[:status] = params[:status] if params.key? :status
      query[:tag] = params[:tag] if params.key? :theme
      query[:type] = params[:type] if params.key? :type
      @blueprints = @blueprints.search(params[:search]) if params.key? :search
      if query.empty?
        @blueprints = @blueprints.all
      else
        @blueprints = @blueprints.where(query)
      end
    end

    def show
      @blueprint = instance
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
      @blueprint = instance
      @blueprint.attributes = request.POST
      if @blueprint.valid?
        @blueprint.save
        render :show, :status => :created
      else
        render_error @blueprint.errors.full_messages.join(', '), :bad_request
      end
    end

    def update_repo
      instance.update_repo
      head :accepted
    end

    def destroy
      @blueprint = instance
      if @blueprint.destroy
        head :no_content
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
  end
end
