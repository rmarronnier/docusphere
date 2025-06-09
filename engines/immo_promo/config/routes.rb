ImmoPromo::Engine.routes.draw do
  # Global document search route
  get 'documents/search', to: 'immo/promo/documents#search', as: :search_documents
  
  # Individual document routes (for direct access)
  resources :documents, controller: 'immo/promo/documents', only: [:show, :update, :destroy] do
    member do
      get :download
      post :share
      post :request_validation
    end
  end

  # Notification Routes (ImmoPromo specific)
  resources :notifications, controller: 'immo/promo/notifications', only: [:index, :show, :destroy] do
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

  # Define routes directly without scope module
  resources :projects, controller: 'immo/promo/projects' do
    member do
      get :dashboard
      get :notifications, to: 'immo/promo/notifications#project_notifications'
    end

    # Document management routes for projects
    resources :documents, controller: 'immo/promo/documents' do
      collection do
        post :bulk_upload
        get :search
        post :bulk_actions
      end
      member do
        get :download
        get :preview
        get :share
        post :share
        get :request_validation
        post :request_validation
      end
    end

    resources :phases, controller: 'immo/promo/phases' do
      member do
        patch :complete
      end
      
      # Document management routes for phases
      resources :documents, controller: 'immo/promo/documents', except: [:new, :edit] do
        collection do
          post :bulk_upload
        end
        member do
          get :download
          post :share
          post :request_validation
        end
      end
      
      resources :tasks, controller: 'immo/promo/tasks' do
        member do
          patch :complete
          patch :assign
        end
        collection do
          get :my_tasks
        end
        
        # Document management routes for tasks
        resources :documents, controller: 'immo/promo/documents', except: [:new, :edit] do
          collection do
            post :bulk_upload
          end
          member do
            get :download
            post :share
            post :request_validation
          end
        end
      end
    end

    resources :stakeholders, controller: 'immo/promo/stakeholders' do
      member do
        patch :approve
        patch :reject
      end
      
      # Document management routes for stakeholders
      resources :documents, controller: 'immo/promo/documents', except: [:new, :edit] do
        collection do
          post :bulk_upload
        end
        member do
          get :download
          post :share
          post :request_validation
        end
      end
    end
    
    resources :permits, controller: 'immo/promo/permits' do
      # Document management routes for permits
      resources :documents, controller: 'immo/promo/documents', except: [:new, :edit] do
        collection do
          post :bulk_upload
        end
        member do
          get :download
          post :share
          post :request_validation
        end
      end
    end
    resources :budgets, controller: 'immo/promo/budgets' do
      member do
        post :duplicate
      end
      resources :budget_lines, controller: 'immo/promo/budget_lines'
    end
    resources :contracts, controller: 'immo/promo/contracts'
    resources :lots, controller: 'immo/promo/lots' do
      resources :reservations, controller: 'immo/promo/reservations'
    end
    resources :risks, controller: 'immo/promo/risks'
    resources :progress_reports, controller: 'immo/promo/progress_reports'
    resources :milestones, controller: 'immo/promo/milestones'
    
    # Routes de coordination des intervenants
    get 'coordination', to: 'immo/promo/coordination#dashboard', as: :coordination_dashboard
    get 'coordination/interventions', to: 'immo/promo/coordination#interventions', as: :coordination_interventions
    get 'coordination/timeline', to: 'immo/promo/coordination#timeline', as: :coordination_timeline
    get 'coordination/performance', to: 'immo/promo/coordination#performance', as: :coordination_performance
    get 'coordination/certifications', to: 'immo/promo/coordination#certifications', as: :coordination_certifications
    get 'coordination/conflicts', to: 'immo/promo/coordination#conflicts_resolution', as: :coordination_conflicts_resolution
    post 'coordination/conflicts', to: 'immo/promo/coordination#conflicts_resolution'
    post 'coordination/assign/:task_id/:stakeholder_id', to: 'immo/promo/coordination#assign_stakeholder', as: :coordination_assign_stakeholder
    post 'coordination/alert', to: 'immo/promo/coordination#send_coordination_alert', as: :send_coordination_alert
    get 'coordination/report', to: 'immo/promo/coordination#export_report', as: :export_coordination_report
    
    # Routes du workflow des permis
    get 'permit_workflow', to: 'immo/promo/permit_workflow#dashboard', as: :permit_workflow_dashboard
    get 'permit_workflow/guide', to: 'immo/promo/permit_workflow#workflow_guide', as: :permit_workflow_guide
    get 'permit_workflow/compliance', to: 'immo/promo/permit_workflow#compliance_checklist', as: :permit_workflow_compliance_checklist
    get 'permit_workflow/timeline', to: 'immo/promo/permit_workflow#timeline_tracker', as: :permit_workflow_timeline_tracker
    get 'permit_workflow/critical_path', to: 'immo/promo/permit_workflow#critical_path', as: :permit_workflow_critical_path
    post 'permit_workflow/submit/:permit_id', to: 'immo/promo/permit_workflow#submit_permit', as: :submit_permit_workflow_permit
    post 'permit_workflow/track/:permit_id', to: 'immo/promo/permit_workflow#track_response', as: :track_permit_workflow_response
    post 'permit_workflow/extend/:permit_id', to: 'immo/promo/permit_workflow#extend_permit', as: :extend_permit_workflow_permit
    post 'permit_workflow/validate/:permit_id/:condition_id', to: 'immo/promo/permit_workflow#validate_condition', as: :validate_permit_workflow_condition
    get 'permit_workflow/package/:permit_id', to: 'immo/promo/permit_workflow#generate_submission_package', as: :generate_permit_workflow_submission_package
    post 'permit_workflow/alert', to: 'immo/promo/permit_workflow#alert_administration', as: :alert_permit_workflow_administration
    get 'permit_workflow/report', to: 'immo/promo/permit_workflow#export_report', as: :export_permit_workflow_report
    
    # Routes du dashboard commercial
    get 'commercial', to: 'immo/promo/commercial_dashboard#dashboard', as: :commercial_dashboard
    get 'commercial/inventory', to: 'immo/promo/commercial_dashboard#lot_inventory', as: :commercial_dashboard_lot_inventory
    get 'commercial/reservations', to: 'immo/promo/commercial_dashboard#reservation_management', as: :commercial_dashboard_reservation_management
    get 'commercial/pricing', to: 'immo/promo/commercial_dashboard#pricing_strategy', as: :commercial_dashboard_pricing_strategy
    get 'commercial/pipeline', to: 'immo/promo/commercial_dashboard#sales_pipeline', as: :commercial_dashboard_sales_pipeline
    get 'commercial/insights', to: 'immo/promo/commercial_dashboard#customer_insights', as: :commercial_dashboard_customer_insights
    post 'commercial/reserve/:lot_id', to: 'immo/promo/commercial_dashboard#create_reservation', as: :create_commercial_dashboard_reservation
    patch 'commercial/lot/:lot_id/status', to: 'immo/promo/commercial_dashboard#update_lot_status', as: :update_commercial_dashboard_lot_status
    get 'commercial/offer/:lot_id', to: 'immo/promo/commercial_dashboard#generate_offer', as: :generate_commercial_dashboard_offer
    get 'commercial/export', to: 'immo/promo/commercial_dashboard#export_inventory', as: :export_commercial_dashboard_inventory
    get 'commercial/report', to: 'immo/promo/commercial_dashboard#sales_report', as: :sales_commercial_dashboard_report
    
    # Routes du dashboard financier
    get 'financial', to: 'immo/promo/financial_dashboard#dashboard', as: :financial_dashboard
    get 'financial/variance', to: 'immo/promo/financial_dashboard#variance_analysis', as: :financial_dashboard_variance_analysis
    get 'financial/cost-control', to: 'immo/promo/financial_dashboard#cost_control', as: :financial_dashboard_cost_control
    get 'financial/cash-flow', to: 'immo/promo/financial_dashboard#cash_flow_management', as: :financial_dashboard_cash_flow_management
    get 'financial/scenarios', to: 'immo/promo/financial_dashboard#budget_scenarios', as: :financial_dashboard_budget_scenarios
    get 'financial/profitability', to: 'immo/promo/financial_dashboard#profitability_analysis', as: :financial_dashboard_profitability_analysis
    post 'financial/adjust/:budget_id', to: 'immo/promo/financial_dashboard#approve_budget_adjustment', as: :approve_financial_dashboard_budget_adjustment
    post 'financial/reallocate', to: 'immo/promo/financial_dashboard#reallocate_budget', as: :reallocate_financial_dashboard_budget
    post 'financial/alert', to: 'immo/promo/financial_dashboard#set_budget_alert', as: :set_financial_dashboard_budget_alert
    get 'financial/report', to: 'immo/promo/financial_dashboard#generate_financial_report', as: :generate_financial_dashboard_report
    get 'financial/export', to: 'immo/promo/financial_dashboard#export_budget_data', as: :export_financial_dashboard_budget_data
    post 'financial/sync', to: 'immo/promo/financial_dashboard#sync_accounting_system', as: :sync_financial_dashboard_accounting
    
    # Routes du monitoring des risques
    get 'risk-monitoring', to: 'immo/promo/risk_monitoring#dashboard', as: :risk_monitoring_dashboard
    get 'risk-monitoring/register', to: 'immo/promo/risk_monitoring#risk_register', as: :risk_monitoring_risk_register
    get 'risk-monitoring/alerts', to: 'immo/promo/risk_monitoring#alert_center', as: :risk_monitoring_alert_center
    get 'risk-monitoring/early-warning', to: 'immo/promo/risk_monitoring#early_warning_system', as: :risk_monitoring_early_warning_system
    post 'risk-monitoring/risk', to: 'immo/promo/risk_monitoring#create_risk', as: :create_risk_monitoring_risk
    patch 'risk-monitoring/risk/:risk_id/assess', to: 'immo/promo/risk_monitoring#update_risk_assessment', as: :update_risk_monitoring_assessment
    post 'risk-monitoring/risk/:risk_id/mitigate', to: 'immo/promo/risk_monitoring#create_mitigation_action', as: :create_risk_monitoring_mitigation
    post 'risk-monitoring/alert/configure', to: 'immo/promo/risk_monitoring#configure_alert', as: :configure_risk_monitoring_alert
    post 'risk-monitoring/alert/:alert_id/acknowledge', to: 'immo/promo/risk_monitoring#acknowledge_alert', as: :acknowledge_risk_monitoring_alert
    get 'risk-monitoring/report', to: 'immo/promo/risk_monitoring#risk_report', as: :risk_risk_monitoring_report
    get 'risk-monitoring/matrix/export', to: 'immo/promo/risk_monitoring#risk_matrix_export', as: :risk_matrix_risk_monitoring_export
  end
end
