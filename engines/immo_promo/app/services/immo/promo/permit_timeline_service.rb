module Immo
  module Promo
    class PermitTimelineService
      PERMIT_DURATIONS = {
        urban_planning: { 
          base: 90, 
          steps: ['Dépôt', 'Instruction', 'Consultation publique', 'Décision']
        },
        construction: { 
          base: 60, 
          large_project: 90, 
          threshold: 1000,
          steps: ['Dépôt', 'Vérification complétude', 'Instruction technique', 'Avis des services', 'Décision']
        },
        environmental: { 
          base: 120,
          steps: ['Dépôt', 'Étude d\'impact', 'Enquête publique', 'Avis environnemental', 'Décision']
        },
        demolition: {
          base: 45,
          steps: ['Dépôt', 'Instruction', 'Décision']
        },
        modification: {
          base: 30,
          steps: ['Dépôt', 'Analyse', 'Décision']
        },
        declaration: {
          base: 30,
          steps: ['Dépôt', 'Vérification', 'Enregistrement']
        }
      }.freeze
      
      attr_reader :project

      def initialize(project)
        @project = project
      end

      def generate_permit_workflow
        workflow_steps = []

        # Demolition permit if needed - must be first
        if needs_demolition_permit?
          workflow_steps << create_permit_workflow_step(
            'demolition',
            'Permis de démolir',
            calculate_timeline_for(:demolition),
            dependencies: []
          )
        end

        # Urban planning permit workflow
        if needs_urban_planning_permit?
          workflow_steps << create_permit_workflow_step(
            'urban_planning',
            'Permis d\'aménager',
            calculate_timeline_for(:urban_planning),
            dependencies: needs_demolition_permit? ? ['demolition'] : []
          )
        end

        # Environmental permits if needed
        if needs_environmental_permits?
          workflow_steps << create_permit_workflow_step(
            'environmental',
            'Autorisations environnementales',
            calculate_timeline_for(:environmental),
            dependencies: []
          )
        end

        # Construction permit workflow - depends on others
        dependencies = []
        dependencies << 'demolition' if needs_demolition_permit?
        dependencies << 'urban_planning' if needs_urban_planning_permit?
        
        workflow_steps << create_permit_workflow_step(
          'construction',
          'Permis de construire',
          calculate_timeline_for(:construction),
          dependencies: dependencies
        )

        # Mark critical path permits
        mark_critical_path_permits(workflow_steps)
        
        workflow_steps
      end

      def generate_permit_timeline
        events = []
        
        project.permits.each do |permit|
          events.concat(permit_events_for(permit))
        end
        
        sorted_events = events.sort_by { |e| e[:date] }
        
        {
          events: sorted_events,
          milestones: extract_milestones(sorted_events),
          statistics: calculate_timeline_statistics
        }
      end

      def calculate_processing_times
        approved_permits = project.permits.approved.where.not(submitted_date: nil, approved_date: nil)
        
        return empty_processing_stats if approved_permits.empty?
        
        processing_times = {}
        all_times = []
        
        approved_permits.group_by(&:permit_type).each do |type, permits|
          times = permits.map { |p| (p.approved_date - p.submitted_date).to_i }
          processing_times[type.to_sym] = calculate_type_statistics(permits, times)
          all_times.concat(times)
        end
        
        build_processing_summary(processing_times, all_times)
      end

      def estimate_duration(permit)
        base = base_duration_for(permit.permit_type)
        estimated = (base * complexity_factor * seasonal_factor).round
        
        {
          base_days: base,
          estimated_days: estimated,
          confidence_range: {
            optimistic: (estimated * 0.8).round,
            pessimistic: (estimated * 1.3).round
          },
          factors: {
            base_duration: base,
            complexity_factor: complexity_factor,
            seasonal_factor: seasonal_factor
          }
        }
      end

      def critical_path_permits
        required_permits = []
        
        # Construction permit is always on critical path
        required_permits << find_or_initialize_permit('construction')
        
        # Urban planning if needed
        if needs_urban_planning_permit?
          required_permits << find_or_initialize_permit('urban_planning')
        end
        
        # Environmental if needed
        if needs_environmental_permits?
          required_permits << find_or_initialize_permit('environmental')
        end
        
        required_permits.compact
      end

      def critical_path_analysis
        critical_permits = critical_path_permits
        
        # Calculate total duration for critical path
        total_duration = 0
        critical_permit_details = []
        bottlenecks = []
        
        critical_permits.each do |permit|
          duration_info = estimate_duration(permit)
          duration = duration_info[:estimated_days]
          
          critical_permit_details << {
            permit: permit,
            duration: duration,
            status: permit.status,
            blocking: permit.status != 'approved'
          }
          
          # Add to total if not yet approved
          if permit.status != 'approved'
            total_duration += duration
            
            # Identify bottlenecks
            if permit.status == 'under_review' && permit.submitted_date
              days_in_review = (Date.current - permit.submitted_date).to_i
              if days_in_review > duration_info[:base_days]
                bottlenecks << {
                  permit: permit,
                  delay: days_in_review - duration_info[:base_days],
                  impact: 'high'
                }
              end
            end
          end
        end
        
        # Calculate buffer days based on project complexity
        buffer_percentage = needs_environmental_permits? ? 0.2 : 0.15
        buffer_days = (total_duration * buffer_percentage).round
        
        # Generate recommendations
        recommendations = generate_critical_path_recommendations(critical_permit_details, bottlenecks)
        
        {
          critical_permits: critical_permit_details,
          total_duration_days: total_duration,
          buffer_days: buffer_days,
          estimated_completion: Date.current + (total_duration + buffer_days).days,
          bottlenecks: bottlenecks,
          recommendations: recommendations
        }
      end

      private

      def calculate_timeline_for(permit_type)
        config = PERMIT_DURATIONS[permit_type]
        base_duration = base_duration_for(permit_type.to_s)
        
        {
          estimated_duration: base_duration,
          steps: config[:steps],
          dependencies: dependencies_for(permit_type),
          submission_deadline: calculate_submission_deadline(permit_type, base_duration)
        }
      end

      def base_duration_for(type)
        config = PERMIT_DURATIONS[type.to_sym]
        return 60 unless config
        
        if type.to_s == 'construction' && project.buildable_surface_area && project.buildable_surface_area > config[:threshold]
          config[:large_project]
        else
          config[:base]
        end
      end

      def complexity_factor
        factors = []
        
        # Surface complexity
        if project.buildable_surface_area
          factors << case project.buildable_surface_area
                    when 0..500 then 0.9
                    when 501..2000 then 1.0
                    when 2001..5000 then 1.1
                    else 1.2
                    end
        end
        
        # Location complexity (simplified)
        factors << 1.1 if project.city&.include?('Paris')
        
        # Environmental complexity
        factors << 1.2 if needs_environmental_permits?
        
        factors.empty? ? 1.0 : factors.sum.to_f / factors.size
      end

      def seasonal_factor
        current_month = Date.current.month
        
        case current_month
        when 7, 8 # July, August - vacation period
          1.2
        when 12, 1 # December, January - holidays
          1.1
        else
          1.0
        end
      end

      def needs_urban_planning_permit?
        project.land_area && project.land_area > 2500
      end

      def needs_environmental_permits?
        project.buildable_surface_area && project.buildable_surface_area > 10000
      end

      def needs_demolition_permit?
        # Check if project has existing structures to demolish
        project.permits.exists?(permit_type: 'demolition') ||
        (project.metadata && project.metadata['has_existing_buildings'] == true) ||
        (project.project_type == 'mixed' && project.buildable_surface_area && project.buildable_surface_area > 500)
      end

      def create_permit_workflow_step(type, name, timeline, dependencies: [])
        {
          type: type,
          name: name,
          timeline: timeline,
          dependencies: dependencies,
          required: true,
          critical_path: false, # Will be set by mark_critical_path_permits
          status: permit_status_for(type),
          estimated_submission: calculate_optimal_submission_date(type),
          estimated_approval: calculate_estimated_approval_date(type),
          requirements: get_permit_requirements(type)
        }
      end

      def permit_status_for(type)
        permit = project.permits.find_by(permit_type: type)
        return 'not_started' unless permit
        
        case permit.status
        when 'approved' then 'completed'
        when 'draft' then 'in_preparation'
        when 'submitted', 'under_review' then 'in_progress'
        else 'blocked'
        end
      end

      def dependencies_for(permit_type)
        case permit_type
        when :construction
          needs_urban_planning_permit? ? ['urban_planning'] : []
        when :environmental
          []
        when :urban_planning
          []
        else
          []
        end
      end

      def calculate_submission_deadline(permit_type, processing_duration)
        construction_start = project.phases.find_by(phase_type: 'construction')&.start_date
        return nil unless construction_start
        
        # Add buffer time
        buffer = 30
        construction_start - (processing_duration + buffer).days
      end

      def permit_events_for(permit)
        events = []
        
        if permit.submitted_date
          events << {
            date: permit.submitted_date,
            type: 'submission',
            permit: permit,
            description: "#{permit.permit_type.humanize} soumis",
            status: 'completed'
          }
        end
        
        if permit.approved_date
          events << {
            date: permit.approved_date,
            type: 'approval',
            permit: permit,
            description: "#{permit.permit_type.humanize} approuvé",
            status: 'completed'
          }
        elsif permit.expected_decision_date
          events << {
            date: permit.expected_decision_date,
            type: 'expected_decision',
            permit: permit,
            description: "Décision attendue pour #{permit.permit_type.humanize}",
            status: 'pending'
          }
        end
        
        if permit.expiry_date && permit.approved?
          events << {
            date: permit.expiry_date,
            type: 'expiry',
            permit: permit,
            description: "Expiration #{permit.permit_type.humanize}",
            status: permit.is_expired? ? 'expired' : 'future'
          }
        end
        
        events
      end

      def find_or_initialize_permit(type)
        project.permits.find_by(permit_type: type) || 
        project.permits.build(permit_type: type, status: 'draft')
      end

      def empty_processing_stats
        { 
          by_type: {}, 
          overall_average: 0.0, 
          fastest_type: nil, 
          slowest_type: nil 
        }
      end

      def calculate_type_statistics(permits, times)
        {
          average_days: times.sum.to_f / times.size,
          count: permits.count,
          min_days: times.min,
          max_days: times.max
        }
      end

      def build_processing_summary(processing_times, all_times)
        overall_avg = all_times.sum.to_f / all_times.size
        
        fastest = processing_times.min_by { |_, v| v[:average_days] }
        slowest = processing_times.max_by { |_, v| v[:average_days] }
        
        {
          by_type: processing_times,
          overall_average: overall_avg.round(2),
          fastest_type: fastest&.first&.to_s,
          slowest_type: slowest&.first&.to_s
        }
      end

      def extract_milestones(events)
        milestones = {}
        
        submission_events = events.select { |e| e[:type] == 'submission' }
        approval_events = events.select { |e| e[:type] == 'approval' }
        
        milestones[:submission_phase] = submission_events.first if submission_events.any?
        milestones[:approval_phase] = approval_events.first if approval_events.any?
        
        # Construction start milestone
        construction_permit = project.permits.find_by(permit_type: 'construction', status: 'approved')
        if construction_permit
          milestones[:construction_start] = {
            date: construction_permit.approved_date + 30.days,
            description: 'Démarrage possible des travaux'
          }
        end
        
        milestones
      end

      def calculate_timeline_statistics
        permits = project.permits
        
        {
          total_permits: permits.count,
          submitted: permits.where.not(submitted_date: nil).count,
          approved: permits.approved.count,
          pending: permits.pending.count,
          average_processing_time: calculate_average_processing_time
        }
      end

      def calculate_average_processing_time
        approved_with_dates = project.permits.approved.where.not(submitted_date: nil, approved_date: nil)
        return 0 if approved_with_dates.empty?
        
        total_days = approved_with_dates.sum { |p| (p.approved_date - p.submitted_date).to_i }
        (total_days.to_f / approved_with_dates.count).round
      end

      def mark_critical_path_permits(workflow_steps)
        critical_types = ['construction']
        critical_types << 'urban_planning' if needs_urban_planning_permit?
        critical_types << 'environmental' if needs_environmental_permits?
        
        workflow_steps.each do |step|
          step[:critical_path] = critical_types.include?(step[:type])
        end
      end

      def calculate_optimal_submission_date(type)
        case type
        when 'demolition'
          project.start_date - 120.days
        when 'urban_planning'
          project.start_date - 150.days
        when 'environmental'
          project.start_date - 180.days
        when 'construction'
          urban_permit = project.permits.find_by(permit_type: 'urban_planning')
          if urban_permit&.approved_date
            urban_permit.approved_date + 7.days
          else
            project.start_date - 90.days
          end
        else
          project.start_date - 60.days
        end
      end

      def calculate_estimated_approval_date(type)
        submission_date = calculate_optimal_submission_date(type)
        duration = base_duration_for(type)
        submission_date + duration.days
      end

      def get_permit_requirements(type)
        case type.to_s
        when 'environmental'
          ['impact_study', 'public_consultation', 'environmental_assessment']
        when 'urban_planning'
          ['site_plan', 'landscape_plan', 'urban_integration_study']
        when 'construction'
          ['architectural_plans', 'structural_calculations', 'thermal_study']
        when 'demolition'
          ['asbestos_diagnostic', 'waste_management_plan', 'structural_survey']
        else
          ['basic_documentation']
        end
      end

      def generate_critical_path_recommendations(critical_permits, bottlenecks)
        recommendations = []
        
        # Recommendations based on permit status
        critical_permits.each do |permit_detail|
          permit = permit_detail[:permit]
          
          case permit.status
          when 'draft'
            recommendations << "Préparer et soumettre le #{permit.permit_type.humanize} au plus vite"
          when 'pending'
            recommendations << "Assurer le suivi du #{permit.permit_type.humanize} en cours d'instruction"
          when 'under_review'
            if bottlenecks.any? { |b| b[:permit].id == permit.id }
              recommendations << "Relancer l'administration pour le #{permit.permit_type.humanize} - retard détecté"
            else
              recommendations << "Suivre l'avancement du #{permit.permit_type.humanize}"
            end
          when 'denied'
            recommendations << "Analyser les raisons du refus et préparer un recours pour le #{permit.permit_type.humanize}"
          when 'approved'
            if permit.permit_type == 'construction' && !permit.persisted?
              recommendations << "Préparer le dossier de demande pour le #{permit.permit_type.humanize}"
            end
          end
        end
        
        # General recommendations
        if bottlenecks.any?
          recommendations << "#{bottlenecks.count} permis présentent des retards - action urgente requise"
        elsif critical_permits.all? { |p| p[:status] == 'approved' }
          recommendations << "Tous les permis critiques sont approuvés - prêt pour le démarrage des travaux"
        elsif critical_permits.any? { |p| p[:status] == 'draft' }
          recommendations << "Finaliser la préparation des permis non soumis"
        end
        
        if needs_environmental_permits? && !project.permits.exists?(permit_type: 'environmental')
          recommendations << "Lancer l'étude d'impact environnemental sans délai - délai long"
        end
        
        recommendations
      end
    end
  end
end