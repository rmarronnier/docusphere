Rails.application.routes.draw do
  # Component preview in development
  if Rails.env.development?
    mount Lookbook::Engine, at: "/rails/lookbook"
  end
  
  get 'home/index'
  devise_for :users
  
  # Document routes outside GED scope  
  resources :documents, only: [:show, :edit, :update] do
    member do
      get :download
    end
  end
  
  # Dashboard Routes
  resource :dashboard, controller: 'dashboard', only: [:show] do
    member do
      patch 'widgets/:id/update', to: 'dashboard#update_widget', as: 'update_widget'
      post 'widgets/:id/refresh', to: 'dashboard#refresh_widget', as: 'refresh_widget'
      post 'widgets/reorder', to: 'dashboard#reorder_widgets', as: 'reorder_widgets'
    end
  end
  
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
    get '/documents/:id/edit', to: 'ged#edit_document', as: 'edit_document'
    
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
      resources :shares, controller: 'document_shares', only: [:new, :create, :destroy], as: 'document_shares'
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
  
  # Additional application routes
  scope '/user' do
    post '/profiles/:id/activate', to: 'users#activate_profile', as: 'activate_profile'
  end
  
  # API routes for frontend
  scope '/api', as: 'api' do
    get '/documents', to: 'api/documents#index', as: 'documents'
    get '/notifications', to: 'api/notifications#index', as: 'notifications'
    get '/tasks', to: 'api/tasks#index', as: 'tasks'
    get '/my-documents', to: 'api/documents#my_documents', as: 'my_documents'
    post '/upload', to: 'api/documents#upload', as: 'upload'
  end
  
  # Additional navigation routes
  get '/notifications', to: 'notifications#index', as: 'all_notifications'
  get '/tasks', to: 'api/tasks#index', as: 'all_tasks'
  get '/my-documents', to: 'api/documents#my_documents', as: 'my_documents'
  
  # PWA routes
  get '/manifest', to: 'pwa#manifest', as: 'pwa_manifest'
  
  # Mount Immo Promo Engine
  mount ImmoPromo::Engine => "/immo/promo"
  
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "home#index"
end
