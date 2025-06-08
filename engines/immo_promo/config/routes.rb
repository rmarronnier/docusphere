ImmoPromo::Engine.routes.draw do
  resources :projects do
    member do
      get :dashboard
    end
    
    resources :phases do
      resources :tasks do
        member do
          get :my_tasks
        end
      end
    end
    
    resources :stakeholders
    resources :permits
    resources :budgets do
      resources :budget_lines
    end
    resources :contracts
    resources :lots do
      resources :reservations
    end
    resources :risks
    resources :progress_reports
    resources :milestones
  end
end