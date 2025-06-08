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

        # Urban planning permit workflow
        if needs_urban_planning_permit?
          workflow_steps << create_permit_workflow_step(
            'urban_planning',
            'Permis d\'aménager',
            calculate_timeline_for(:urban_planning)
          )
        end

        # Construction permit workflow
        workflow_steps << create_permit_workflow_step(
          'construction',
          'Permis de construire',
          calculate_timeline_for(:construction)
        )

        # Environmental permits if needed
        if needs_environmental_permits?
          workflow_steps << create_permit_workflow_step(
            'environmental',
            'Autorisations environnementales',
            calculate_timeline_for(:environmental)
          )
        end

        # Demolition permit if needed
        if needs_demolition_permit?
          workflow_steps << create_permit_workflow_step(
            'demolition',
            'Permis de démolir',
            calculate_timeline_for(:demolition)
          )
        end

        workflow_steps
      end

      def generate_permit_timeline
        events = []
        
        project.permits.each do |permit|
          events.concat(permit_events_for(permit))
        end
        
        events.sort_by { |e| e[:date] }
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
        base * complexity_factor * seasonal_factor
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
        
        if type.to_s == 'construction' && project.total_surface_area && project.total_surface_area > config[:threshold]
          config[:large_project]
        else
          config[:base]
        end
      end

      def complexity_factor
        factors = []
        
        # Surface complexity
        if project.total_surface_area
          factors << case project.total_surface_area
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
        project.total_surface_area && project.total_surface_area > 10000
      end

      def needs_demolition_permit?
        # Simplified logic - would check for existing buildings
        false
      end

      def create_permit_workflow_step(type, name, timeline)
        {
          type: type,
          name: name,
          timeline: timeline,
          required: true,
          status: permit_status_for(type)
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
        
        if permit.approval_date || permit.approved_date
          approval_date = permit.approval_date || permit.approved_date
          events << {
            date: approval_date,
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
    end
  end
end