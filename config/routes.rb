require 'resque/server'

Autotune::Engine.routes.draw do

  resources :themes,
            :constraints => { :id => Autotune::SLUG_OR_ID_REGEX }
  get 'themes/:id/reset',
      :to => 'themes#reset',
      :constraints => { :id => Autotune::SLUG_OR_ID_REGEX }

  resources :blueprints,
            :constraints => { :id => Autotune::SLUG_OR_ID_REGEX }

  get 'blueprints/:id/update_repo',
      :to => 'blueprints#update_repo',
      :constraints => { :id => Autotune::SLUG_OR_ID_REGEX }
  get 'blueprints/:id/new_project',
      :to => 'application#index',
      :constraints => { :id => Autotune::SLUG_OR_ID_REGEX }

  resources :projects,
            :constraints => { :id => Autotune::SLUG_OR_ID_REGEX }
  get 'projects/:id/update_snapshot',
      :to => 'projects#update_snapshot',
      :constraints => { :id => Autotune::SLUG_OR_ID_REGEX }
  get 'projects/:id/build',
      :to => 'projects#build',
      :constraints => { :id => Autotune::SLUG_OR_ID_REGEX }
  get 'projects/:id/build_and_publish',
      :to => 'projects#build_and_publish',
      :constraints => { :id => Autotune::SLUG_OR_ID_REGEX }
  get 'projects/:id/duplicate',
      :to => 'application#index',
      :constraints => { :id => Autotune::SLUG_OR_ID_REGEX }
  get 'projects/:id/cancel_repeat_build',
      :to => 'projects#cancel_repeat_build',
      :constraints => { :id => Autotune::SLUG_OR_ID_REGEX }

  get 'projects/:id/build_data',
      :to => 'projects#build_data',
      :constraints => { :id => Autotune::SLUG_OR_ID_REGEX }
  post 'projects/:id/build_data',
       :to => 'projects#build_data',
       :constraints => { :id => Autotune::SLUG_OR_ID_REGEX }
  post 'projects/build_data',
       :to => 'projects#build_data'
  post 'projects/create_google_doc',
       :to => 'projects#create_google_doc'

  get 'changemessages' => 'changemessages#index'

  get 'messages' => 'messages#index'
  post 'messages/send' => 'messages#send_message'

  get 'builder' => 'application#index'
  root 'application#index'

  match '/auth/:provider/callback' => 'sessions#create',  :via => [:get, :post]
  get '/auth/failure'              => 'sessions#failure'
  get '/logout'                    => 'sessions#destroy', :as => :logout
  get '/login'                     => 'sessions#new',     :as => :login
  get '/auth_dev_tools'            => 'sessions#auth_dev_tools'

  # Add a protected `/resque` route for checking on workers
  resque_web_constraint = lambda do |request|
    current_user = Autotune::User.find_by_api_key(
      request.env['rack.session']['api_key'])
    current_user.present? && current_user.meta['roles'].include?('superuser')
  end
  constraints resque_web_constraint do
    mount Resque::Server.new, :at => '/resque'
  end

  match '*all' => 'application#cors_preflight_check',
        :via => [:options]
end
