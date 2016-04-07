require_dependency 'autotune/application_controller'
require 'autotune/google_docs'
require 'redis'

module Autotune
  # API for projects
  class ProjectsController < ApplicationController
    before_action :respond_to_html
    before_action :require_superuser, :only => [:update_snapshot]
    model Project

    rescue_from ActiveRecord::UnknownAttributeError do |exc|
      render_error exc.message, :bad_request
    end

    before_action :only => [:show, :update, :destroy, :build, :build_and_publish] do
      unless current_user.role?(:superuser) ||
             instance.user == current_user ||
             current_user.role?(:editor => instance.theme.value)
        render_error 'Forbidden', :forbidden
      end
    end

    def new; end

    def edit; end

    def index
      @projects = Project
      # Filter and search query
      query = {}

      query[:status] = params[:status] if params.key? :status

      if params.key? :blueprint
        blueprint = Blueprint.find_by_slug(params[:blueprint])
        query[:blueprint_id] = blueprint.id
      elsif params.key? :blueprint_id
        query[:blueprint_id] = params[:blueprint_id]
      elsif params.key? :blueprint_title
        query[:blueprint_id] = params[:blueprint_title]
      end

      if params.key? :pub_status
        if params[:pub_status] == 'published'
          @projects = @projects.where.not(:published_at => nil)
        else
          @projects = @projects.where(:published_at => nil)
        end
      end

      if params.key? :search
        users = User.search(params[:search]).pluck(:id)
        sql = @projects.search_sql(params[:search])

        sql[0] = "(#{sql[0]}) OR (user_id IN (?))"
        sql << users

        @projects = @projects.where(sql)
      end

      if params.key? :theme
        theme = Theme.find_by_value(params[:theme])
        query[:theme_id] = theme.id
      end

      unless current_user.role? :superuser
        if current_user.role? :editor
          @projects = @projects.where(
            '(user_id = ? OR theme_id IN (?))',
            current_user.id, current_user.editor_themes.pluck(:id))
        else
          query[:user_id] = current_user.id
        end
      end

      @projects = @projects.where(query)

      if params.key? :type
        @blueprints = Blueprint
        @blueprint_ids = @blueprints.where(:type => params[:type]).pluck(:id)
        @projects = @projects.where(:blueprint_id => @blueprint_ids)
      end

      page = params[:page] || 1
      per_page = params[:per_page] || 15
      @projects = @projects.paginate(:page => page, :per_page => per_page)
      link_str = '<%s>; rel="%s"'
      links = [
        link_str % [
          projects_url(:page => @projects.current_page, :per_page => per_page), 'page'],
        link_str % [
          projects_url(:page => 1, :per_page => per_page), 'first'],
        link_str % [
          projects_url(:page => @projects.total_pages, :per_page => per_page), 'last']
      ]
      if @projects.next_page
        links << link_str % [
          projects_url(:page => @projects.next_page, :per_page => per_page), 'next']
      end
      if @projects.previous_page
        links << link_str % [
          projects_url(:page => @projects.previous_page, :per_page => per_page), 'prev']
      end
      headers['Link'] = links.join(', ')
      headers['X-Total'] = @projects.count
    end

    def show
      @project = instance
    end

    def create
      @project = Project.new(:user => current_user)
      @project.attributes = select_from_post :title, :slug, :blueprint_id, :data

      if request.POST.key? 'blueprint'
        @project.blueprint = Blueprint.find_by_slug request.POST['blueprint']
      end

      if request.POST.key? 'theme'
        @project.theme = Theme.find_by_value request.POST['theme']

        # is this user allowed to use this theme?
        unless @project.theme.nil? ||
               current_user.author_themes.include?(@project.theme)
          return render_error(
            "You can't use the #{@project.theme.label} theme. Please " \
            'choose another theme or contact support',
            :bad_request)
        end
      end

      unless @project.data.nil?
        # make sure data doesn't contain title, slug or theme
        @project.data.delete('title')
        @project.data.delete('slug')
        @project.data.delete('theme')
      end

      if @project.valid?
        @project.status = 'built' if @project.live?
        @project.save
        @project.build unless @project.live?

        render :show, :status => :created
      else
        render_error @project.errors.full_messages.join(', '), :bad_request
      end
    end

    def update
      @project = instance
      @project.user = current_user if @project.user.nil?
      @project.attributes = select_from_post :title, :slug, :data

      if request.POST.key? 'theme'
        @project.theme = Theme.find_by_value request.POST['theme']

        # is this user allowed to use this theme?
        unless @project.theme.nil? ||
               current_user.author_themes.include?(@project.theme)
          return render_error(
            "You can't use the #{@project.theme.label} theme. Please " \
            'choose another theme or contact support',
            :bad_request)
        end
      end

      # make sure data doesn't contain title, slug or theme
      %w(title slug theme base_url asset_base_url).each do |k|
        @project.data.delete(k)
      end

      if @project.valid?
        @project.status = 'built' if @project.live?
        @project.save
        @project.build unless @project.live?

        render :show
      else
        render_error @project.errors.full_messages.join(', '), :bad_request
      end
    end

    def preview_build_data
      @project = instance
      @build_data = request.POST
      if @build_data['google_doc_url'] && request.GET[:force_update]
        cache_key = "googledoc#{GoogleDocs.key_from_url(@build_data['google_doc_url'])}"
        Rails.cache.delete(cache_key)
      end

      # Get the deployer object
      deployer = @project.deployer(:preview)

      # Run the before build deployer hook
      deployer.before_build(@build_data, {}, current_user)
      render :json => @build_data
    rescue => exc
      if @project.present? && @project.meta['error_message'].present?
        render_error @project.meta['error_message'], :bad_request
      elsif exc.is_a?(Signet::AuthorizationError)
        render_error 'There was an error authenticating your Google account', :bad_request
        logger.error "Google Auth error: #{exc.message}"
      else
        raise
      end
    end

    def create_spreadsheet
      current_auth = current_user.authorizations.find_by!(:provider => 'google_oauth2')
      google_client = GoogleDocs.new(
        :refresh_token => current_auth.credentials['refresh_token'],
        :access_token => current_auth.credentials['token'],
        :expires_at => current_auth.credentials['expires_at'])
      spreadsheet_copy = google_client.copy(request.POST['_json'])

      if Autotune.configuration.google_auth_domain.present?
        google_client.share_with_domain(
          spreadsheet_copy[:id], Autotune.configuration.google_auth_domain)
      end

      render :json => { :google_doc_url => spreadsheet_copy[:url] }
    rescue Signet::AuthorizationError => exc
      render_error 'There was an error authenticating your Google account', :bad_request
      logger.error "Google Auth error: #{exc.message}"
    end

    def update_snapshot
      instance.update_snapshot
      render_accepted
    end

    def build
      instance.build
      render_accepted
    end

    def build_and_publish
      instance.build_and_publish
      render_accepted
    end

    def destroy
      @project = instance
      if @project.destroy
        head :no_content
      else
        render_error @project.errors.full_messages.join(', '), :bad_request
      end
    end

    private
  end
end
