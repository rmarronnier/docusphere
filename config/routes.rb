Rails.application.routes.draw do
  get 'home/index'
  devise_for :users
  
  # Search Routes
  get '/search', to: 'search#index', as: 'search'
  get '/search/suggestions', to: 'search#suggestions', as: 'search_suggestions'
  
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
