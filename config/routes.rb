require 'resque/server'

Autotune::Engine.routes.draw do
  resources :blueprints,
            :constraints => { :id => Autotune::SLUG_OR_ID_REGEX }

  get 'blueprints/:id/update_repo',
      :to => 'blueprints#update_repo',
      :constraints => { :id => Autotune::SLUG_OR_ID_REGEX }
  get 'blueprints/:id/new_project',
      :to => 'application#index',
      :constraints => { :id => Autotune::SLUG_OR_ID_REGEX }
  match 'blueprints/:id/new_project/update_project_data',
      :to => 'blueprints#update_project_data',
      :constraints => { :id => Autotune::SLUG_OR_ID_REGEX },
      :via => [:get, :post]

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
  match 'projects/:id/update_project_data',
      :to => 'projects#update_project_data',
      :constraints => { :id => Autotune::SLUG_OR_ID_REGEX },
      :via => [:get, :post]
  get 'projects/:id/duplicate',
      :to => 'application#index',
      :constraints => { :id => Autotune::SLUG_OR_ID_REGEX }
  get '/changemessages' => 'changemessages#index'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'application#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  match '/auth/:provider/callback' => 'sessions#create',  :via => [:get, :post]
  get '/auth/failure'              => 'sessions#failure'
  get '/logout'                    => 'sessions#destroy', :as => :logout
  get '/login'                     => 'sessions#new',     :as => :login

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
