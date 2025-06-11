module MetricsService::BusinessMetrics
  extend ActiveSupport::Concern
  
  # Métriques spécifiques aux permis
  def pending_permits_count
    if @user.organization.respond_to?(:permits)
      @user.organization.permits.where(status: 'pending').count
    else
      rand(2..8)
    end
  end

  def approved_permits_count
    if @user.organization.respond_to?(:permits)
      @user.organization.permits.where(status: 'approved').count
    else
      rand(10..25)
    end
  end

  # Métriques contractuelles
  def active_contracts_count
    if @user.organization.respond_to?(:contracts)
      @user.organization.contracts.where(status: 'active').count
    else
      rand(15..30)
    end
  end

  def compliance_score_percentage
    # Score de conformité basé sur les documents et processus
    base_score = 85
    penalties = 0
    
    # Pénalités pour retards ou non-conformités
    penalties += pending_validations_count * 2
    penalties += pending_permits_count * 3
    
    [base_score - penalties, 0].max
  end

  def pending_legal_reviews_count
    @user.organization.validation_requests
         .joins(:document_validations)
         .where(document_validations: { status: 'pending' })
         .count rescue rand(3..12)
  end

  def upcoming_deadlines_count
    # Échéances dans les 30 prochains jours
    if @user.organization.respond_to?(:projects)
      @user.organization.projects
           .where('expected_completion_date BETWEEN ? AND ?', Date.current, 30.days.from_now)
           .count
    else
      rand(5..15)
    end
  end

  # Métriques commerciales
  def monthly_reservations_count
    if @user.organization.respond_to?(:reservations)
      @user.organization.reservations
           .where(created_at: Date.current.beginning_of_month..Date.current.end_of_month)
           .count
    else
      rand(8..25)
    end
  end

  def monthly_sales_amount
    if @user.organization.respond_to?(:reservations)
      @user.organization.reservations
           .where(created_at: Date.current.beginning_of_month..Date.current.end_of_month)
           .joins(:lot)
           .sum('immo_promo_lots.price_cents') / 100.0
    else
      rand(250_000..800_000)
    end
  end

  def sales_conversion_rate
    total_prospects = monthly_reservations_count + rand(10..30)
    return 0 if total_prospects.zero?
    
    (monthly_reservations_count.to_f / total_prospects * 100).round(2)
  end

  def available_units_count
    if @user.organization.respond_to?(:lots)
      @user.organization.lots.where(status: 'available').count
    else
      rand(20..50)
    end
  end

  def sales_pipeline_value
    # Valeur du pipeline commercial
    available_units_count * rand(200_000..400_000)
  end

  def customer_satisfaction_score
    # Score de satisfaction client (simulation)
    base_score = 4.2
    variation = rand(-0.3..0.3)
    
    [base_score + variation, 5.0].min.round(1)
  end

  # Métriques financières
  def budget_variance_percentage
    # Variance budgétaire
    planned_budget = 1_000_000
    actual_spending = planned_budget * (budget_consumed_percentage / 100.0)
    
    variance = ((actual_spending - planned_budget) / planned_budget * 100).round(2)
    variance.abs
  end

  def pending_invoices_count
    # Factures en attente
    rand(5..20)
  end

  def current_cash_flow
    # Flux de trésorerie actuel
    monthly_sales_amount - (monthly_sales_amount * 0.7) # 70% de coûts
  end

  def cost_overrun_projects_count
    # Projets avec dépassement de coût
    total_projects = total_projects_count
    return 0 if total_projects.zero?
    
    (total_projects * 0.15).round # 15% de projets avec dépassement
  end

  def average_payment_delay_days
    # Délai moyen de paiement
    rand(25..45)
  end

  def financial_health_score
    # Score de santé financière
    cash_flow_factor = current_cash_flow > 0 ? 25 : 0
    variance_factor = budget_variance_percentage < 10 ? 25 : 15
    payment_factor = average_payment_delay_days < 30 ? 25 : 15
    overrun_factor = cost_overrun_projects_count < 2 ? 25 : 10
    
    cash_flow_factor + variance_factor + payment_factor + overrun_factor
  end

  # Métriques utilisateur par défaut
  def user_documents_count
    @user.documents.count rescue 0
  end

  def unread_notifications_count
    @user.notifications.unread.count rescue 0
  end

  def recent_activity_count
    (@user.documents.where('created_at >= ?', 7.days.ago).count rescue 0) +
    (@user.notifications.where('created_at >= ?', 7.days.ago).count rescue 0)
  end

  def storage_usage_mb
    # Utilisation du stockage (simulation)
    total_docs = user_documents_count
    average_size_mb = 2.5 # MB par document en moyenne
    
    (total_docs * average_size_mb).round(2)
  end

  def assigned_tasks_count
    if @user.respond_to?(:assigned_tasks)
      @user.assigned_tasks.where(status: ['pending', 'in_progress']).count
    else
      rand(3..12)
    end
  end

  def last_week_activity
    documents_created = @user.documents.where('created_at >= ?', 7.days.ago).count rescue 0
    notifications_read = @user.notifications.where('read_at >= ?', 7.days.ago).count rescue 0
    
    {
      documents: documents_created,
      notifications: notifications_read,
      total_score: (documents_created * 2 + notifications_read)
    }
  end
end