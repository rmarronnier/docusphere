class DefaultWidgetService
  WIDGET_CONFIGS = {
    direction: [
      { type: 'portfolio_overview', width: 2, height: 1 },
      { type: 'financial_summary', width: 1, height: 1 },
      { type: 'risk_matrix', width: 1, height: 1 },
      { type: 'approval_queue', width: 1, height: 2 },
      { type: 'kpi_dashboard', width: 2, height: 1 },
      { type: 'team_performance', width: 1, height: 1 }
    ],
    chef_projet: [
      { type: 'project_timeline', width: 2, height: 2 },
      { type: 'task_kanban', width: 2, height: 2 },
      { type: 'team_availability', width: 1, height: 1 },
      { type: 'milestone_tracker', width: 1, height: 1 },
      { type: 'recent_documents', width: 2, height: 1 }
    ],
    juriste: [
      { type: 'permit_status', width: 2, height: 1 },
      { type: 'contract_tracker', width: 1, height: 1 },
      { type: 'compliance_dashboard', width: 1, height: 1 },
      { type: 'regulatory_calendar', width: 2, height: 1 },
      { type: 'legal_documents', width: 2, height: 1 }
    ],
    commercial: [
      { type: 'sales_pipeline', width: 2, height: 2 },
      { type: 'inventory_status', width: 1, height: 1 },
      { type: 'conversion_metrics', width: 1, height: 1 },
      { type: 'top_prospects', width: 1, height: 1 },
      { type: 'monthly_targets', width: 1, height: 1 }
    ],
    architecte: [
      { type: 'project_plans', width: 2, height: 2 },
      { type: 'pending_validations', width: 1, height: 1 },
      { type: 'modification_requests', width: 1, height: 1 },
      { type: 'technical_documents', width: 2, height: 1 }
    ],
    controleur: [
      { type: 'budget_variance', width: 2, height: 1 },
      { type: 'cash_flow', width: 1, height: 1 },
      { type: 'pending_invoices', width: 1, height: 1 },
      { type: 'cost_analysis', width: 2, height: 2 },
      { type: 'financial_alerts', width: 2, height: 1 }
    ]
  }.freeze
  
  def initialize(profile)
    @profile = profile
  end
  
  def generate_widgets
    base_widgets = WIDGET_CONFIGS[@profile.profile_type.to_sym] || default_widgets
    
    # Enrichir avec la configuration par défaut
    base_widgets.map do |widget|
      widget.merge(
        config: default_config_for(widget[:type]),
        visible: true
      )
    end
  end
  
  private
  
  def default_widgets
    [
      { type: 'recent_activity', width: 2, height: 1 },
      { type: 'my_documents', width: 2, height: 1 },
      { type: 'notifications_summary', width: 1, height: 1 },
      { type: 'quick_links', width: 1, height: 1 }
    ]
  end
  
  def default_config_for(widget_type)
    case widget_type
    when 'portfolio_overview'
      { 
        show_inactive: false, 
        group_by: 'status',
        refresh_interval: 300 # 5 minutes
      }
    when 'financial_summary'
      {
        currency: 'EUR',
        show_variance: true,
        comparison_period: 'month'
      }
    when 'task_kanban'
      {
        columns: ['todo', 'in_progress', 'review', 'done'],
        show_assignee: true,
        enable_drag_drop: true
      }
    when 'project_timeline'
      {
        view_mode: 'month',
        show_dependencies: true,
        show_milestones: true
      }
    when 'permit_status'
      {
        show_expiring: true,
        expiry_threshold_days: 30,
        group_by: 'project'
      }
    when 'sales_pipeline'
      {
        stages: ['prospect', 'qualification', 'negotiation', 'closed'],
        show_value: true,
        currency: 'EUR'
      }
    when 'budget_variance'
      {
        comparison_type: 'actual_vs_budget',
        show_percentage: true,
        highlight_threshold: 10
      }
    else
      {}
    end
  end
end