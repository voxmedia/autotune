require_dependency 'autotune/application_controller'

module Autotune
  # API for blueprints
  class BlueprintsController < ApplicationController
    before_action :respond_to_html
    before_action :require_superuser, :only => [:create, :update, :update_repo, :destroy]
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
      @blueprints = @blueprints.search(params[:search], :title) if params.key? :search

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
      @blueprint.attributes = select_from_post :title, :repo_url, :slug
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
      @blueprint.attributes = select_from_post :title, :repo_url, :slug, :status
      if @blueprint.valid?
        @blueprint.save
        render :show
      else
        render_error @blueprint.errors.full_messages.join(', '), :bad_request
      end
    end

    def update_repo
      instance.update_repo
      render_accepted
    end

    def destroy
      @blueprint = instance
      if @blueprint.projects.count > 0
        render_error(
          'This blueprint is in use. You must delete the projects which use this blueprint.',
          :bad_request)
      elsif @blueprint.destroy
        head :no_content
      else
        render_error @blueprint.errors.full_messages.join(', '), :bad_request
      end
    end
  end
end
