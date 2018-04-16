require_dependency 'autotune/application_controller'
require 'autotune/google_docs'
require 'redis'

module Autotune
  # API for projects
  class ProjectsController < ApplicationController
    model Project
    skip_before_action :require_google_login,
                       :only => [:index, :show]

    before_action :only => [:index, :show] do
      require_google_login if google_auth_required? && !accepts_json?
    end

    before_action :respond_to_html

    rescue_from ActiveRecord::UnknownAttributeError do |exc|
      render_error exc.message, :bad_request
    end

    before_action :only => [:show, :update, :update_snapshot, :destroy, :build, :build_and_publish] do
      unless current_user.role?(:superuser) ||
             instance.user == current_user ||
             current_user.role?(:editor => instance.group.slug) ||
             current_user.role?(:designer => instance.group.slug)
        render_error 'Forbidden', :forbidden
      end
    end

    def new; end

    def edit; end

    def index
      @projects = Project
      # Filter and search query
      query = {}

      query[:status] = params[:status] if params[:status].present?

      if params[:blueprint].present?
        if params[:blueprint] == 'bespoke'
          query[:bespoke] = true
        else
          blueprint = Blueprint.find_by_slug(params[:blueprint])
          query[:blueprint_id] = blueprint.id
        end
      elsif params[:blueprint_id].present?
        if params[:blueprint_id].to_i < 1
          query[:bespoke] = true
        else
          query[:blueprint_id] = params[:blueprint_id]
        end
      end

      if params[:pub_status].present?
        if params[:pub_status] == 'published'
          @projects = @projects.where.not(:published_at => nil)
        else
          @projects = @projects.where(:published_at => nil)
        end
      end

      if params[:search].present?
        users = User.search(params[:search]).pluck(:id)
        sql = @projects.search_sql(params[:search])

        sql[0] = "(#{sql[0]}) OR (user_id IN (?))"
        sql << users

        @projects = @projects.where(sql)
      end

      if params[:theme].present?
        theme = Theme.find_by_slug(params[:theme])
        query[:theme_id] = theme.id
      end

      if params[:group].present?
        group = Group.find_by_slug(params[:group])
        query[:group_id] = group.id
      end

      unless current_user.role? :superuser
        if current_user.role? [:editor, :designer]
          @projects = @projects.where(
            '(user_id = ? OR group_id IN (?))',
            current_user.id, current_user.editor_groups.pluck(:id))
        else
          query[:user_id] = current_user.id
        end
      end

      @projects = @projects.where(query)

      if params[:type].present?
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
      headers['X-Total'] = @projects.count.to_s
    end

    def show
      @project = instance
    end

    def create
      @project = Project.new(:user => current_user)

      return unless handle_post!

      Rails.logger.debug(params[:blueprint_config])

      if @project.valid?
        @project.status = 'built' if @project.live?
        @project.save
        @project.build(current_user) unless @project.live?

        render :show, :status => :created
      else
        render_error @project.errors.full_messages.join(', '), :bad_request
      end
    end

    def update
      @project = instance
      @project.user = current_user if @project.user.nil?

      return unless handle_post!

      if @project.valid?
        @project.status = 'built' if @project.live?
        @project.save
        @project.build(current_user) unless @project.live?

        render :show
      else
        render_error @project.errors.full_messages.join(', '), :bad_request
      end
    end

    def build_data
      @project = instance

      @build_data = request.method == 'POST' ? request.POST : @project.data

      # Bust google doc cache if we are forcing an update
      if @build_data['google_doc_url'].present? && request.GET[:force_update]
        cache_key = "googledoc#{GoogleDocs.key_from_url(@build_data['google_doc_url'])}"
        Rails.cache.delete(cache_key)
      end

      # Get the deployer object
      deployer = @project.deployer(:preview, :user => current_user)

      # Run the before build deployer hook
      deployer.before_build(@build_data, {})
      render :json => @build_data
    rescue
      if @project && @project.meta.present? && @project.meta['error_message'].present?
        render_error @project.meta['error_message'], :bad_request
      else
        raise
      end
    end

    def create_google_doc
      current_auth = current_user.authorizations.find_by!(:provider => 'google_oauth2')
      google_client = GoogleDocs.new(
        :refresh_token => current_auth.credentials['refresh_token'],
        :access_token => current_auth.credentials['token'],
        :expires_at => current_auth.credentials['expires_at']
      )

      current_auth.credentials['refresh_token'] = google_client.auth.refresh_token
      current_auth.credentials['token'] = google_client.auth.access_token
      current_auth.credentials['expires_at'] = google_client.auth.expires_at
      current_auth.save!

      doc_copy = google_client.copy(request.POST['google_doc_id'])

      if Autotune.configuration.google_auth_domain.present?
        google_client.share_with_domain(
          doc_copy[:id], Autotune.configuration.google_auth_domain
        )
      end

      render :json => { :google_doc_url => doc_copy[:url] }
    end

    def update_snapshot
      instance.update_snapshot(current_user)
      render_accepted
    end

    def build
      instance.build(current_user)
      render_accepted
    end

    def build_and_publish
      instance.build_and_publish(current_user)
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

    def handle_post!
      @project.attributes = select_from_post(
        :title, :slug, :bespoke, :blueprint_id, :blueprint_version,
        :blueprint_repo_url, :blueprint_config, :data)

      if request.POST.key? 'blueprint'
        @project.blueprint = Blueprint.find_by_slug request.POST['blueprint']
      end

      if request.POST.key? 'theme'
        @project.theme = Theme.find_by_slug request.POST['theme']
        @project.group = @project.theme.group

        # is this user allowed to use this theme?
        unless @project.theme.nil? ||
               current_user.author_themes.include?(@project.theme)
          render_error(
            "You can't use the #{@project.theme.title} theme. Please " \
            'choose another theme or contact support',
            :bad_request)
          return false
        end
      end

      # make sure data doesn't contain title, slug or theme
      %w(title slug theme base_url asset_base_url).each do |k|
        @project.data.delete(k)
      end

      true
    end
  end
end
