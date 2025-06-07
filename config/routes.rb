Rails.application.routes.draw do
  get 'home/index'
  devise_for :users
  
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
  end
  
  # Immo Promo Routes
  namespace :immo do
    namespace :promo do
      get '/', to: 'projects#dashboard', as: 'dashboard'
      
      resources :projects do
        member do
          patch :complete
          get :dashboard
        end
        
        resources :phases do
          member do
            patch :complete
          end
          
          resources :tasks do
            member do
              patch :complete
              patch :assign
            end
            
            collection do
              get :my_tasks
            end
            
            resources :time_logs, only: [:create, :destroy]
          end
        end
        
        resources :stakeholders do
          resources :certifications, only: [:create, :update, :destroy]
          resources :contracts, only: [:create, :update, :destroy]
        end
        
        resources :permits do
          resources :permit_conditions, only: [:create, :update, :destroy]
        end
        
        resources :lots do
          resources :reservations, only: [:create, :update, :destroy]
          resources :lot_specifications, only: [:create, :update, :destroy]
        end
        
        resources :budgets do
          resources :budget_lines, only: [:create, :update, :destroy]
        end
        
        resources :milestones
        resources :risks
        resources :progress_reports
      end
      
      # Standalone resources
      resources :user_groups do
        member do
          patch :add_member
          patch :remove_member
          patch :make_admin
        end
      end
    end
  end
  
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "home#index"
end
