Rails.application.routes.draw do
  get 'home/index'
  devise_for :users
  
  # Search Routes
  get '/search', to: 'search#index', as: 'search'
  get '/search/advanced', to: 'search#advanced', as: 'advanced_search'
  get '/search/suggestions', to: 'search#suggestions', as: 'search_suggestions'
  
  # Notification Routes
  resources :notifications, only: [:index, :show, :destroy] do
    member do
      patch :mark_as_read
    end
    collection do
      patch :mark_all_as_read
      patch :bulk_mark_as_read
      delete :bulk_destroy
      get :dropdown
      get :urgent
      get :stats
    end
  end
  
  # Notification Preferences Routes
  resources :notification_preferences, only: [:index, :update] do
    collection do
      patch :bulk_update
      patch :reset_to_defaults
      get :preview
    end
  end
  
  # Basket Routes
  resources :baskets do
    member do
      post :share
      post :add_document
      delete :remove_document
      get :download_all
    end
  end
  
  # Admin Routes
  resources :users do
    member do
      patch :toggle_active
    end
  end
  
  resources :user_groups do
    member do
      post :add_member
      delete 'remove_member/:user_id', to: 'user_groups#remove_member', as: 'remove_member'
    end
  end
  
  resources :tags do
    collection do
      get :autocomplete
    end
  end
  
  # GED Routes
  scope '/ged', as: 'ged' do
    get '/', to: 'ged#dashboard', as: 'dashboard'
    get '/spaces/:id', to: 'ged#show_space', as: 'space'
    get '/folders/:id', to: 'ged#show_folder', as: 'folder'
    get '/documents/:id', to: 'ged#show_document', as: 'document'
    
    # AJAX routes for modals
    post '/spaces', to: 'ged#create_space', as: 'create_space'
    post '/folders', to: 'ged#create_folder', as: 'create_folder'
    post '/documents', to: 'ged#upload_document', as: 'upload_document'
    
    # Document operations
    get '/documents/:id/download', to: 'ged#download_document', as: 'download_document'
    get '/documents/:id/preview', to: 'ged#preview_document', as: 'preview_document'
    get '/documents/:id/status', to: 'ged#document_status', as: 'document_status'
    post '/documents/:id/lock', to: 'ged#lock_document', as: 'lock_document'
    post '/documents/:id/unlock', to: 'ged#unlock_document', as: 'unlock_document'
    
    # Document versioning
    get '/documents/:id/versions', to: 'ged#document_versions', as: 'document_versions'
    post '/documents/:id/versions', to: 'ged#create_document_version', as: 'create_document_version'
    post '/documents/:id/versions/:version_number/restore', to: 'ged#restore_document_version', as: 'restore_document_version'
    get '/documents/:id/versions/:version_number/download', to: 'ged#download_document_version', as: 'download_document_version'
    
    # Document validation routes
    resources :documents, only: [] do
      resources :validations, controller: 'document_validations', only: [:index, :show, :new, :create] do
        member do
          post :approve
          post :reject
        end
      end
    end
    
    # My validation requests
    get '/my-validation-requests', to: 'document_validations#my_requests', as: 'my_validation_requests'
    
    # Bulk document operations
    post '/documents/bulk', to: 'ged#bulk_action', as: 'bulk_document_action'
    
    # Permissions management
    get '/spaces/:id/permissions', to: 'ged#space_permissions', as: 'space_permissions'
    patch '/spaces/:id/permissions', to: 'ged#update_space_permissions', as: 'update_space_permissions'
    get '/folders/:id/permissions', to: 'ged#folder_permissions', as: 'folder_permissions' 
    patch '/folders/:id/permissions', to: 'ged#update_folder_permissions', as: 'update_folder_permissions'
    get '/documents/:id/permissions', to: 'ged#document_permissions', as: 'document_permissions'
    patch '/documents/:id/permissions', to: 'ged#update_document_permissions', as: 'update_document_permissions'
  end
  
  # Mount Immo Promo Engine
  mount ImmoPromo::Engine => "/immo/promo"
  
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "home#index"
end
