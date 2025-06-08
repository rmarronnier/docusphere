class Immo::Promo::PermitTrackerService
  attr_reader :project, :current_user

  def initialize(project, current_user)
    @project = project
    @current_user = current_user
  end

  def track_permit_deadlines
    deadline_alerts = []
    
    project.permits.each do |permit|
      # Check submission deadlines
      if permit.draft? && should_submit_soon?(permit)
        deadline_alerts << {
          permit: permit,
          type: 'submission_due',
          urgency: calculate_urgency(permit),
          message: generate_submission_message(permit),
          action_required: 'Finaliser et soumettre le dossier'
        }
      end
      
      # Check response deadlines
      if permit.under_review? && response_overdue?(permit)
        deadline_alerts << {
          permit: permit,
          type: 'response_overdue',
          urgency: 'high',
          message: "Réponse attendue depuis #{overdue_days(permit)} jours",
          action_required: 'Relancer les services instructeurs'
        }
      end
      
      # Check expiry dates
      if permit.approved? && expiring_soon?(permit)
        deadline_alerts << {
          permit: permit,
          type: 'expiring',
          urgency: calculate_expiry_urgency(permit),
          message: "Expire le #{permit.expiry_date.strftime('%d/%m/%Y')}",
          action_required: determine_expiry_action(permit)
        }
      end
    end
    
    deadline_alerts.sort_by { |alert| urgency_score(alert[:urgency]) }.reverse
  end

  def generate_permit_workflow
    workflow_steps = []
    
    # Urban planning permit workflow
    if needs_urban_planning_permit?
      workflow_steps << create_permit_workflow_step(
        'urban_planning',
        'Permis d\'aménager',
        calculate_urban_planning_timeline
      )
    end
    
    # Construction permit workflow
    workflow_steps << create_permit_workflow_step(
      'construction',
      'Permis de construire',
      calculate_construction_permit_timeline
    )
    
    # Environmental permits if needed
    if needs_environmental_permits?
      workflow_steps << create_permit_workflow_step(
        'environmental',
        'Autorisations environnementales',
        calculate_environmental_timeline
      )
    end
    
    workflow_steps
  end

  def check_regulatory_compliance
    compliance_issues = []
    
    # RT 2020 compliance
    unless project.lots.all? { |lot| lot.lot_specifications.where(specification_type: 'environmental').exists? }
      compliance_issues << {
        regulation: 'RT 2020',
        severity: 'critical',
        description: 'Spécifications environnementales manquantes pour certains lots',
        action: 'Compléter les spécifications RT 2020 pour tous les lots'
      }
    end
    
    # Accessibility compliance
    if project.residential? && project.total_units > 20
      accessible_units = project.lots.joins(:lot_specifications)
                                    .where(lot_specifications: { specification_type: 'accessibility' })
                                    .count
      required_accessible = (project.total_units * 0.05).ceil
      
      if accessible_units < required_accessible
        compliance_issues << {
          regulation: 'Accessibilité PMR',
          severity: 'high',
          description: "#{required_accessible} logements accessibles requis, #{accessible_units} prévus",
          action: 'Modifier la conception pour respecter le quota PMR'
        }
      end
    end
    
    # Fire safety compliance
    unless has_fire_safety_approval?
      compliance_issues << {
        regulation: 'Sécurité incendie',
        severity: 'critical',
        description: 'Avis de la commission de sécurité manquant',
        action: 'Soumettre le dossier à la commission de sécurité'
      }
    end
    
    compliance_issues
  end

  def estimate_approval_timeline
    timeline_estimates = {}
    
    project.permits.where.not(status: ['approved', 'denied']).each do |permit|
      base_duration = base_permit_duration(permit.permit_type)
      complexity_factor = calculate_complexity_factor(permit)
      seasonal_factor = calculate_seasonal_factor(permit)
      
      estimated_days = (base_duration * complexity_factor * seasonal_factor).round
      
      timeline_estimates[permit.id] = {
        permit: permit,
        estimated_duration_days: estimated_days,
        estimated_approval_date: permit.submission_date ? 
          permit.submission_date + estimated_days.days : 
          Date.current + estimated_days.days,
        confidence_level: calculate_confidence_level(permit, estimated_days),
        factors: {
          base_duration: base_duration,
          complexity_factor: complexity_factor,
          seasonal_factor: seasonal_factor
        }
      }
    end
    
    timeline_estimates
  end

  private

  def should_submit_soon?(permit)
    # Logic to determine if permit should be submitted soon
    # based on project timeline and dependencies
    project.phases.where(phase_type: 'permits').any? do |phase|
      phase.start_date && phase.start_date <= 2.weeks.from_now
    end
  end

  def response_overdue?(permit)
    return false unless permit.expected_decision_date
    Date.current > permit.expected_decision_date
  end

  def expiring_soon?(permit)
    return false unless permit.expiry_date
    permit.expiry_date <= 3.months.from_now
  end

  def calculate_urgency(permit)
    return 'critical' if should_submit_immediately?(permit)
    return 'high' if should_submit_soon?(permit)
    'medium'
  end

  def should_submit_immediately?(permit)
    # Critical if project phase starts in less than a week
    project.phases.where(phase_type: 'permits').any? do |phase|
      phase.start_date && phase.start_date <= 1.week.from_now
    end
  end

  def generate_submission_message(permit)
    case permit.permit_type
    when 'urban_planning'
      "Permis d'aménager à soumettre - délai d'instruction : 3 mois"
    when 'construction'
      "Permis de construire à soumettre - délai d'instruction : 2-3 mois"
    when 'environmental'
      "Autorisation environnementale à soumettre - délai variable"
    else
      "Dossier de #{permit.permit_type.humanize} à soumettre"
    end
  end

  def overdue_days(permit)
    return 0 unless permit.expected_decision_date
    (Date.current - permit.expected_decision_date).to_i
  end

  def calculate_expiry_urgency(permit)
    return 'critical' if permit.expiry_date <= 1.month.from_now
    return 'high' if permit.expiry_date <= 2.months.from_now
    'medium'
  end

  def determine_expiry_action(permit)
    days_until_expiry = (permit.expiry_date - Date.current).to_i
    
    if days_until_expiry <= 30
      'Commencer les travaux immédiatement ou demander une prorogation'
    elsif days_until_expiry <= 60
      'Planifier le démarrage des travaux ou préparer une demande de prorogation'
    else
      'Surveiller et planifier le démarrage des travaux'
    end
  end

  def urgency_score(urgency)
    case urgency
    when 'critical' then 3
    when 'high' then 2
    when 'medium' then 1
    else 0
    end
  end

  def needs_urban_planning_permit?
    # Logic to determine if urban planning permit is needed
    project.total_surface_area && project.total_surface_area > 1000
  end

  def needs_environmental_permits?
    # Logic to determine if environmental permits are needed
    project.commercial? || (project.total_surface_area && project.total_surface_area > 5000)
  end

  def create_permit_workflow_step(permit_type, name, timeline)
    {
      permit_type: permit_type,
      name: name,
      estimated_duration: timeline[:duration],
      steps: timeline[:steps],
      dependencies: timeline[:dependencies]
    }
  end

  def calculate_urban_planning_timeline
    {
      duration: 90, # days
      steps: [
        'Préparation du dossier (15 jours)',
        'Dépôt en mairie (1 jour)',
        'Instruction (75 jours)',
        'Décision (notification)'
      ],
      dependencies: ['Études préliminaires', 'Relevés topographiques']
    }
  end

  def calculate_construction_permit_timeline
    {
      duration: project.total_surface_area > 1000 ? 90 : 60,
      steps: [
        'Préparation du dossier (20 jours)',
        'Dépôt en mairie (1 jour)',
        'Instruction (60-90 jours)',
        'Décision (notification)'
      ],
      dependencies: ['Plans d\'architecte', 'Études techniques']
    }
  end

  def calculate_environmental_timeline
    {
      duration: 120,
      steps: [
        'Étude d\'impact (30 jours)',
        'Dossier ICPE (15 jours)',
        'Enquête publique (30 jours)',
        'Instruction (45 jours)'
      ],
      dependencies: ['Études environnementales']
    }
  end

  def has_fire_safety_approval?
    project.permits.where(permit_type: 'safety', status: 'approved').exists? ||
    project.stakeholders.where(stakeholder_type: 'control_office').any? do |stakeholder|
      stakeholder.certifications.where(certification_type: 'safety', is_valid: true).exists?
    end
  end

  def base_permit_duration(permit_type)
    case permit_type
    when 'urban_planning' then 90
    when 'construction' then project.total_surface_area > 1000 ? 90 : 60
    when 'environmental' then 120
    when 'demolition' then 30
    when 'modification' then 30
    else 60
    end
  end

  def calculate_complexity_factor(permit)
    complexity = 1.0
    
    # Size factor
    if project.total_surface_area
      complexity *= 1.2 if project.total_surface_area > 5000
      complexity *= 1.1 if project.total_surface_area > 1000
    end
    
    # Type factor
    complexity *= 1.3 if project.mixed?
    complexity *= 1.2 if project.commercial?
    
    # Location factor (assume urban areas are more complex)
    complexity *= 1.1 if project.city&.match?(/Paris|Lyon|Marseille/)
    
    complexity
  end

  def calculate_seasonal_factor(permit)
    current_month = Date.current.month
    # Summer months may have delays due to vacations
    return 1.2 if [7, 8].include?(current_month)
    # December may have delays due to holidays
    return 1.1 if current_month == 12
    1.0
  end

  def calculate_confidence_level(permit, estimated_days)
    # Base confidence on historical data and complexity
    base_confidence = 0.7
    
    # Reduce confidence for complex projects
    base_confidence -= 0.1 if estimated_days > 90
    base_confidence -= 0.1 if project.mixed? || project.commercial?
    
    # Increase confidence for simple projects
    base_confidence += 0.1 if estimated_days < 60
    base_confidence += 0.1 if project.residential?
    
    [base_confidence, 0.95].min
  end
end