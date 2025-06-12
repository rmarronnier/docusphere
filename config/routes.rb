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
    get '/documents/:id/edit', to:'ged#edit_document', as: 'edit_document'
    get '/documents/new', to: 'ged#new_document', as: 'new_document'
    get '/documents', to: 'ged#index_documents', as: 'documents'
    get '/my-documents', to: 'ged#my_documents', as: 'my_documents'
    get '/upload', to: 'ged#new_document', as: 'upload'
    
    # AJAX routes for modals
    post '/spaces', to: 'ged#create_space', as: 'create_space'
    post '/folders', to: 'ged#create_folder', as: 'create_folder'
    post '/documents', to: 'ged#upload_document', as: 'upload_document'
    
    # Document operations
    get '/documents/:id/download', to: 'ged#download_document', as: 'download_document'
    get '/documents/:id/preview', to: 'ged#preview_document', as: 'preview_document'
    get '/documents/:id/status', to: 'ged#document_status', as: 'document_status'
    patch '/documents/:id/lock', to: 'ged#lock_document', as: 'lock_document'
    patch '/documents/:id/unlock', to: 'ged#unlock_document', as: 'unlock_document'
    post '/documents/:id/duplicate', to: 'ged#duplicate_document', as: 'duplicate_document'
    patch '/documents/:id/archive', to: 'ged#archive_document', as: 'archive_document'
    patch '/documents/:id/move', to: 'ged#move_document', as: 'move_document'
    post '/documents/:id/request_validation', to: 'ged#request_validation', as: 'request_validation_document'
    post '/documents/:id/generate_public_link', to: 'ged#generate_public_link', as: 'generate_public_link_document'
    patch '/documents/:id/update_metadata', to: 'ged#update_metadata', as: 'update_metadata_document'
    get '/documents/:id/metadata', to: 'ged#metadata', as: 'metadata_document'
    get '/documents/:id/edit_metadata', to: 'ged#edit_metadata', as: 'edit_metadata_document'
    
    # Document versioning
    get '/documents/:id/versions', to: 'ged#document_versions', as: 'document_versions'
    get '/documents/:id/versions/compare', to: 'ged#compare_document_versions', as: 'compare_document_versions'
    get '/documents/:id/versions/:version_number', to: 'ged#show_document_version', as: 'document_version'
    post '/documents/:id/versions', to: 'ged#create_document_version', as: 'create_document_version'
    post '/documents/:id/versions/:version_number/restore', to: 'ged#restore_document_version', as: 'restore_document_version'
    get '/documents/:id/versions/:version_number/download', to: 'ged#download_document_version', as: 'download_document_version'
    
    # Document audit and activities
    get '/documents/:id/audit_trail', to: 'ged#document_audit_trail', as: 'audit_trail_document'
    get '/documents/:id/activities', to: 'ged#document_activities', as: 'document_activities'
    
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
    post '/upload', to: 'api/documents#upload', as: 'document_upload'
  end
  
  # Additional navigation routes
  get '/notifications', to: 'notifications#index', as: 'all_notifications'
  get '/tasks', to: 'api/tasks#index', as: 'all_tasks'
  get '/my-documents', to: 'api/documents#my_documents', as: 'my_documents'
  get '/help', to: 'help#index', as: 'help'
  
  # Global upload alias (for component compatibility)
  get '/upload_page', to: 'ged#new_document', as: 'upload'
  
  # Business-specific dashboard routes
  get '/client-documents', to: 'business#client_documents', as: 'client_documents'
  get '/compliance-dashboard', to: 'business#compliance_dashboard', as: 'compliance_dashboard'
  
  # Business proposal management
  resources :proposals, only: [:new, :create, :show, :edit, :update, :destroy] do
    member do
      post :send_to_client
      post :duplicate
      patch :accept
      patch :reject
    end
  end
  
  # Business-specific routes for different profiles
  # Direction profile routes
  resources :reports do
    collection do
      get :executive_summary
      get :performance_dashboard
      get :export
    end
  end

  # Project management routes
  resources :planning do
    collection do
      get :gantt
      get :calendar
      get :milestones
    end
  end
  
  resources :resources do
    collection do
      get :allocation
      get :capacity
      get :conflicts
    end
  end

  # Commercial profile routes
  resources :clients do
    member do
      get :documents
      get :contracts
      get :interactions
    end
  end
  
  resources :contracts do
    member do
      post :sign
      post :renew
      get :preview
    end
  end

  # Legal profile routes
  namespace :legal do
    resources :contracts, as: :legal_contracts do
      member do
        post :approve
        post :reject
        get :review
      end
    end
    
    resources :deadlines, as: :legal_deadlines do
      collection do
        get :calendar
        get :upcoming
        get :overdue
      end
    end
  end

  # Finance profile routes
  resources :invoices do
    member do
      post :approve
      post :send_to_client
      get :export_pdf
    end
    collection do
      get :dashboard
      get :overdue
    end
  end
  
  resources :budgets do
    collection do
      get :dashboard
      get :variance_report
    end
  end
  
  resources :expenses, path: 'expense-reports' do
    member do
      post :approve
      post :reject
    end
  end

  # Technical profile routes
  resources :specifications do
    collection do
      get :templates
      get :by_project
    end
  end
  
  resources :technical_docs do
    collection do
      get :by_category
      get :search
    end
  end
  
  resources :support_tickets do
    member do
      post :assign
      post :resolve
      post :escalate
    end
    collection do
      get :my_tickets
      get :unassigned
    end
  end

  # Stakeholder management (for main app, complement engine routes)
  resources :stakeholders, only: [:index, :show] do
    member do
      get :documents, to: 'stakeholders#documents', as: 'documents'
    end
  end
  
  # Enhanced document sharing routes
  post '/documents/:id/share', to: 'documents#share', as: 'share_document'
  get '/documents/:id/share/new', to: 'documents#new_share', as: 'new_share_document'
  
  # Project document management (outside ImmoPromo scope)
  get '/projects/:project_id/documents', to: 'documents#project_documents', as: 'project_documents'
  post '/projects/:project_id/documents/upload', to: 'documents#upload_project_document', as: 'upload_project_document'
  
  # Alias for upload_document_path(project) -> upload_project_document_path(project)
  post '/projects/:id/upload', to: 'documents#upload_project_document', as: 'upload_document'
  
  # Validation workflow enhancements
  resources :validations, only: [:show, :index] do
    member do
      post :approve
      post :reject
      post :request_review
    end
  end
  
  # Activity routes
  get '/activities', to: 'activities#index', as: 'ged_activities'
  
  # PWA routes
  get '/manifest', to: 'pwa#manifest', as: 'pwa_manifest'
  
  # Simple route aliases for component compatibility
  get '/projects', to: redirect('/immo/promo/projects'), as: 'projects'
  get '/projects/:id', to: redirect('/immo/promo/projects/%{id}'), as: 'project'

  # Mount Immo Promo Engine
  mount ImmoPromo::Engine => "/immo/promo"
  
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "home#index"
end
