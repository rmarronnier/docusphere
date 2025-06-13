# Concern for permit management functionality in ImmoPromo
module PermitManageable
  extend ActiveSupport::Concern

  # Permit types with their characteristics
  PERMIT_TYPES = {
    urban_planning: {
      duration: 90,
      complexity: :high,
      public_consultation: true,
      prerequisites: []
    },
    construction: {
      duration: 60,
      complexity: :medium,
      public_consultation: false,
      prerequisites: [:urban_planning]
    },
    environmental: {
      duration: 120,
      complexity: :high,
      public_consultation: true,
      prerequisites: []
    },
    demolition: {
      duration: 45,
      complexity: :low,
      public_consultation: false,
      prerequisites: []
    },
    modification: {
      duration: 30,
      complexity: :low,
      public_consultation: false,
      prerequisites: [:construction]
    }
  }.freeze

  # Generate comprehensive permit workflow
  def generate_permit_workflow(project)
    required_permits = determine_required_permits(project)
    workflow_steps = []
    
    # Sort permits by dependencies
    sorted_permits = sort_permits_by_dependencies(required_permits)
    
    sorted_permits.each_with_index do |permit_type, index|
      workflow_steps << create_permit_step(permit_type, project, index)
    end
    
    # Add milestone checkpoints
    workflow_steps += create_milestone_checkpoints(sorted_permits, project)
    
    workflow_steps.sort_by { |step| step[:position] }
  end

  # Track permit progress and compliance
  def track_permit_progress(permit)
    current_step = permit.current_workflow_step
    return nil unless current_step
    
    {
      permit_id: permit.id,
      permit_type: permit.permit_type,
      current_step: current_step.name,
      progress_percentage: calculate_permit_progress(permit),
      days_elapsed: calculate_days_elapsed(permit),
      days_remaining: calculate_days_remaining(permit),
      is_on_track: permit_on_track?(permit),
      compliance_status: check_compliance_status(permit),
      next_actions: determine_next_actions(permit),
      alerts: generate_permit_alerts(permit)
    }
  end

  # Check permit compliance
  def check_permit_compliance(permit)
    compliance_checks = {
      documentation_complete: check_documentation_completeness(permit),
      deadlines_met: check_deadline_compliance(permit),
      requirements_satisfied: check_requirements_compliance(permit),
      public_consultation: check_public_consultation_compliance(permit),
      environmental_approval: check_environmental_compliance(permit)
    }
    
    overall_compliant = compliance_checks.values.all?
    
    {
      overall_compliant: overall_compliant,
      compliance_score: calculate_compliance_score(compliance_checks),
      checks: compliance_checks,
      recommendations: generate_compliance_recommendations(compliance_checks)
    }
  end

  # Generate permit timeline with critical dates
  def generate_permit_timeline(project)
    permits = project.permits.includes(:workflow_steps)
    timeline = []
    
    permits.each do |permit|
      permit_timeline = generate_single_permit_timeline(permit)
      timeline.concat(permit_timeline)
    end
    
    # Sort by date and add dependencies
    timeline.sort_by! { |event| event[:date] }
    timeline = add_timeline_dependencies(timeline)
    
    {
      events: timeline,
      critical_path: identify_critical_path(timeline),
      total_duration: calculate_total_timeline_duration(timeline),
      risk_periods: identify_risk_periods(timeline)
    }
  end

  # Estimate permit duration with confidence intervals
  def estimate_permit_duration(permit_type, project_complexity: :medium)
    base_duration = PERMIT_TYPES[permit_type][:duration]
    
    # Adjust for project complexity
    complexity_multiplier = case project_complexity
    when :low then 0.8
    when :medium then 1.0
    when :high then 1.3
    when :very_high then 1.6
    else 1.0
    end
    
    adjusted_duration = (base_duration * complexity_multiplier).round
    
    # Add confidence intervals (±20%)
    min_duration = (adjusted_duration * 0.8).round
    max_duration = (adjusted_duration * 1.2).round
    
    {
      estimated_days: adjusted_duration,
      confidence_range: {
        min: min_duration,
        max: max_duration
      },
      factors: analyze_duration_factors(permit_type, project_complexity)
    }
  end

  # Critical path analysis for permits
  def analyze_critical_path(project)
    permits = project.permits.includes(:dependencies)
    
    # Build dependency graph
    graph = build_permit_dependency_graph(permits)
    
    # Find critical path using topological sort
    critical_path = find_longest_path(graph)
    
    # Calculate float time for non-critical permits
    float_times = calculate_float_times(permits, critical_path)
    
    {
      critical_permits: critical_path,
      total_critical_duration: critical_path.sum { |p| p[:duration] },
      float_times: float_times,
      bottlenecks: identify_bottlenecks(critical_path),
      recommendations: generate_optimization_recommendations(critical_path, float_times)
    }
  end

  private

  def determine_required_permits(project)
    permits = []
    
    # Based on project characteristics
    permits << :demolition if project.requires_demolition?
    permits << :environmental if project.requires_environmental_study?
    permits << :urban_planning if project.requires_urban_planning?
    permits << :construction # Always required
    permits << :modification if project.is_modification?
    
    permits.uniq
  end

  def sort_permits_by_dependencies(permit_types)
    sorted = []
    remaining = permit_types.dup
    
    while remaining.any?
      # Find permits with no unmet dependencies
      ready_permits = remaining.select do |permit_type|
        prerequisites = PERMIT_TYPES[permit_type][:prerequisites]
        prerequisites.all? { |prereq| sorted.include?(prereq) }
      end
      
      if ready_permits.empty?
        # Circular dependency or error - add remaining permits
        sorted.concat(remaining)
        break
      end
      
      sorted.concat(ready_permits)
      remaining -= ready_permits
    end
    
    sorted
  end

  def create_permit_step(permit_type, project, position)
    config = PERMIT_TYPES[permit_type]
    
    {
      name: "Permis #{permit_type.to_s.humanize}",
      permit_type: permit_type,
      position: position,
      estimated_duration: config[:duration],
      complexity: config[:complexity],
      public_consultation_required: config[:public_consultation],
      prerequisites: config[:prerequisites],
      deliverables: generate_permit_deliverables(permit_type),
      stakeholders: identify_required_stakeholders(permit_type)
    }
  end

  def create_milestone_checkpoints(permits, project)
    checkpoints = []
    
    # Add checkpoint after each major permit
    major_permits = [:urban_planning, :environmental, :construction]
    
    permits.each_with_index do |permit_type, index|
      if major_permits.include?(permit_type)
        checkpoints << {
          name: "Validation #{permit_type.to_s.humanize}",
          type: :checkpoint,
          position: index + 0.5,
          dependencies: [permit_type],
          duration: 5, # Review period
          required_actions: generate_checkpoint_actions(permit_type)
        }
      end
    end
    
    checkpoints
  end

  def calculate_permit_progress(permit)
    completed_steps = permit.workflow_steps.where(status: 'completed').count
    total_steps = permit.workflow_steps.count
    
    return 0 if total_steps.zero?
    (completed_steps.to_f / total_steps * 100).round(2)
  end

  def calculate_days_elapsed(permit)
    return 0 unless permit.started_at
    (Date.current - permit.started_at.to_date).to_i
  end

  def calculate_days_remaining(permit)
    return 0 unless permit.estimated_end_date
    remaining = (permit.estimated_end_date - Date.current).to_i
    [remaining, 0].max
  end

  def permit_on_track?(permit)
    return true unless permit.estimated_end_date
    
    expected_progress = calculate_expected_progress(permit)
    actual_progress = calculate_permit_progress(permit)
    
    actual_progress >= expected_progress * 0.9 # 10% tolerance
  end

  def calculate_expected_progress(permit)
    return 0 unless permit.started_at && permit.estimated_end_date
    
    total_duration = (permit.estimated_end_date - permit.started_at.to_date).to_i
    elapsed_duration = calculate_days_elapsed(permit)
    
    return 100 if elapsed_duration >= total_duration
    (elapsed_duration.to_f / total_duration * 100).round(2)
  end

  def check_compliance_status(permit)
    checks = check_permit_compliance(permit)
    
    if checks[:overall_compliant]
      :compliant
    elsif checks[:compliance_score] >= 0.8
      :mostly_compliant
    elsif checks[:compliance_score] >= 0.6
      :partially_compliant
    else
      :non_compliant
    end
  end

  def determine_next_actions(permit)
    current_step = permit.current_workflow_step
    return [] unless current_step
    
    actions = []
    
    # Based on current step and permit status
    case current_step.step_type
    when 'submission'
      actions << "Finaliser et soumettre le dossier"
    when 'review'
      actions << "Suivre l'avancement de l'instruction"
    when 'public_consultation'
      actions << "Monitorer la consultation publique"
    when 'decision'
      actions << "Attendre la décision administrative"
    end
    
    # Add compliance-based actions
    compliance = check_permit_compliance(permit)
    unless compliance[:overall_compliant]
      actions.concat(compliance[:recommendations])
    end
    
    actions.uniq
  end

  def generate_permit_alerts(permit)
    alerts = []
    
    # Deadline alerts
    days_remaining = calculate_days_remaining(permit)
    if days_remaining <= 7
      alerts << { type: :urgent, message: "Échéance dans #{days_remaining} jours" }
    elsif days_remaining <= 14
      alerts << { type: :warning, message: "Échéance dans #{days_remaining} jours" }
    end
    
    # Progress alerts
    unless permit_on_track?(permit)
      alerts << { type: :warning, message: "Retard détecté sur le planning" }
    end
    
    # Compliance alerts
    compliance = check_permit_compliance(permit)
    unless compliance[:overall_compliant]
      alerts << { type: :error, message: "Problèmes de conformité détectés" }
    end
    
    alerts
  end

  def check_documentation_completeness(permit)
    required_docs = permit.required_documents
    submitted_docs = permit.submitted_documents
    
    return true if required_docs.empty?
    
    completion_rate = submitted_docs.count.to_f / required_docs.count
    completion_rate >= 1.0
  end

  def check_deadline_compliance(permit)
    # Check if all steps are completed within their deadlines
    permit.workflow_steps.all? do |step|
      step.deadline.nil? || step.completed_at.nil? || step.completed_at <= step.deadline
    end
  end

  def check_requirements_compliance(permit)
    # Check if all permit requirements are satisfied
    permit.requirements.all?(&:satisfied?)
  end

  def check_public_consultation_compliance(permit)
    return true unless PERMIT_TYPES[permit.permit_type.to_sym][:public_consultation]
    
    permit.public_consultation_completed? && permit.public_consultation_valid?
  end

  def check_environmental_compliance(permit)
    return true unless permit.requires_environmental_approval?
    
    permit.environmental_approval_received? && permit.environmental_conditions_met?
  end

  def calculate_compliance_score(checks)
    return 0.0 if checks.empty?
    
    passed_checks = checks.values.count(true)
    total_checks = checks.size
    
    passed_checks.to_f / total_checks
  end

  def generate_compliance_recommendations(checks)
    recommendations = []
    
    checks.each do |check_name, passed|
      next if passed
      
      case check_name
      when :documentation_complete
        recommendations << "Compléter la documentation manquante"
      when :deadlines_met
        recommendations << "Rattraper les retards sur les échéances"
      when :requirements_satisfied
        recommendations << "Satisfaire les exigences non remplies"
      when :public_consultation
        recommendations << "Finaliser la consultation publique"
      when :environmental_approval
        recommendations << "Obtenir l'approbation environnementale"
      end
    end
    
    recommendations
  end

  def generate_permit_deliverables(permit_type)
    case permit_type
    when :urban_planning
      ["Plans de situation", "Plans de masse", "Plans des façades", "Notice descriptive"]
    when :construction
      ["Plans d'architecture", "Plans techniques", "Étude de sol", "Calculs de structure"]
    when :environmental
      ["Étude d'impact", "Mesures compensatoires", "Plan de gestion environnementale"]
    when :demolition
      ["Plans de démolition", "Procédures de sécurité", "Gestion des déchets"]
    when :modification
      ["Plans modifiés", "Justification des modifications", "Impact sur l'existant"]
    else
      []
    end
  end

  def identify_required_stakeholders(permit_type)
    case permit_type
    when :urban_planning
      ["Architecte", "Urbaniste", "Géomètre"]
    when :construction
      ["Architecte", "Bureau d'études", "Économiste"]
    when :environmental
      ["Expert environnemental", "Écologue", "Hydrogéologue"]
    when :demolition
      ["Coordinateur sécurité", "Expert amiante", "Gestionnaire déchets"]
    when :modification
      ["Architecte", "Bureau d'études"]
    else
      []
    end
  end

  def generate_checkpoint_actions(permit_type)
    case permit_type
    when :urban_planning
      ["Valider la conformité urbanistique", "Vérifier les prescriptions"]
    when :environmental
      ["Valider les mesures environnementales", "Confirmer les autorisations"]
    when :construction
      ["Valider les plans d'exécution", "Confirmer la conformité technique"]
    else
      ["Validation générale du permis"]
    end
  end
end