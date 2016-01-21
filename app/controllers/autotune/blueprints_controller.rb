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

    def preview_build_data
      @project = instance
      @build_data = request.POST
      cache_key = "googledoc#{@build_data['google_doc_url'].match(/[-\w]{25,}/).to_s}"
      if request.GET[:force_update]
        Rails.cache.delete(cache_key)
      end

      # Get the deployer object
      deployer = @project.deployer(:preview)

      # Run the before build deployer hook
      deployer.before_build(@build_data, {})
      render :json => @build_data
    end

    def create_spreadsheet
      @project = instance
      @ss_key = request.POST
      if @project['meta']
        cur_user = User.find(@project.meta['current_user'])
      else
        cur_user = User.find_by_name(@project.config['authors'][0].split('<')[0])
      end

      current_auth = cur_user.authorizations.find_by!(:provider => 'google_oauth2')
      google_client = GoogleDocs.new(current_auth)
      spreadsheet_copy = google_client.copy(@ss_key['_json'])
      set_permissions = google_client.insert_permission(spreadsheet_copy[:id], 'voxmedia.com', 'domain', 'writer')
      render :json => {:google_doc_url => spreadsheet_copy[:url]}
    end

    def builder; end
  end
end
