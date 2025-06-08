ImmoPromo::Engine.routes.draw do
  # Define routes directly without scope module
  resources :projects, controller: 'immo/promo/projects' do
    member do
      get :dashboard
    end

    resources :phases, controller: 'immo/promo/phases' do
      member do
        patch :complete
      end
      
      resources :tasks, controller: 'immo/promo/tasks' do
        member do
          patch :complete
          patch :assign
        end
        collection do
          get :my_tasks
        end
      end
    end

    resources :stakeholders, controller: 'immo/promo/stakeholders'
    resources :permits, controller: 'immo/promo/permits'
    resources :budgets, controller: 'immo/promo/budgets' do
      resources :budget_lines, controller: 'immo/promo/budget_lines'
    end
    resources :contracts, controller: 'immo/promo/contracts'
    resources :lots, controller: 'immo/promo/lots' do
      resources :reservations, controller: 'immo/promo/reservations'
    end
    resources :risks, controller: 'immo/promo/risks'
    resources :progress_reports, controller: 'immo/promo/progress_reports'
    resources :milestones, controller: 'immo/promo/milestones'
  end
end
