# Routes to add to config/routes.rb

# Business-specific routes

# Direction profile routes
resources :reports do
  member do
    get :export
  end
  collection do
    get :templates
    post :generate_from_template
  end
end

# Commercial profile routes
resources :clients do
  member do
    get :documents
    get :history
  end
  collection do
    post :import
    get :export
  end
end

resources :contracts do
  member do
    post :sign
    post :renew
    post :terminate
  end
  collection do
    get :templates
    post :generate_from_template
  end
end

# Juridique profile routes
resources :legal_contracts do
  member do
    post :validate
    get :review
    post :archive
  end
  collection do
    get :compliance_dashboard
    get :clause_library
    get :generate_legal_report
  end
end

resources :legal_deadlines do
  member do
    post :complete
    post :extend
  end
  collection do
    get :calendar
    get :dashboard
    get :export
  end
end

# Finance profile routes
resources :invoices do
  member do
    post :send_invoice
    post :mark_as_paid
    post :generate_reminder
  end
  collection do
    post :bulk_actions
    get :reconciliation
    get :aging_report
  end
end

get '/budget-dashboard', to: 'budget_dashboard#index', as: 'budget_dashboard'
get '/budget-dashboard/:project_id', to: 'budget_dashboard#show', as: 'project_budget_dashboard'
post '/budget-dashboard/:project_id/update', to: 'budget_dashboard#update', as: 'update_project_budget'

resources :expense_reports do
  member do
    post :submit_for_approval
    post :approve
    post :reject
    post :reimburse
  end
  collection do
    get :pending_approval
    get :my_reports
  end
end

# Technique profile routes
resources :specifications do
  member do
    post :validate_technical
    post :request_changes
  end
  collection do
    get :templates
    get :by_project
  end
end

get '/technical-docs', to: 'technical_docs#index', as: 'technical_docs'
get '/technical-docs/new', to: 'technical_docs#new', as: 'new_technical_doc'
post '/technical-docs', to: 'technical_docs#create', as: 'create_technical_doc'
get '/technical-docs/:id', to: 'technical_docs#show', as: 'technical_doc'

resources :support_tickets do
  member do
    post :assign
    post :resolve
    post :close
    post :reopen
  end
  collection do
    get :my_tickets
    get :unassigned
    get :statistics
  end
end

# Engine routes updates
# In engines/immo_promo/config/routes.rb
namespace :immo do
  namespace :promo do
    resources :planning do
      member do
        get :calendar
        get :timeline
        patch :update_task
        post :reschedule
      end
    end
    
    resources :resources do
      member do
        get :workload
        post :assign
      end
      collection do
        get :allocation
        get :availability
        get :capacity_planning
        get :skills_matrix
      end
    end
  end
end