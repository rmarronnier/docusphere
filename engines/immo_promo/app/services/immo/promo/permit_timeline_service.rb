module Immo
  module Promo
    class PermitTimelineService
      include PermitManageable
      include ProjectCalculable
      include ::Reportable
      
      def initialize(project)
        @project = project
        super() # Initialize concerns
      end

      # Generate comprehensive permit workflow using PermitManageable
      def generate_project_permit_workflow
        generate_permit_workflow(@project)
      end

      # Generate timeline for all project permits
      def generate_comprehensive_timeline
        timeline_data = generate_permit_timeline(@project)
        
        # Enhance with calculations
        timeline_data.merge(
          critical_path: analyze_critical_path(@project),
          processing_statistics: calculate_processing_statistics,
          duration_estimates: calculate_duration_estimates
        )
      end

      # Track all permits progress
      def track_all_permits_progress
        permits = @project.permits.includes(:workflow_steps)
        
        permits.map do |permit|
          track_permit_progress(permit)
        end
      end

      # Generate compliance report for all permits
      def generate_permits_compliance_report
        permits = @project.permits
        compliance_data = {
          project: project_summary(@project),
          permits_compliance: permits.map { |permit| check_permit_compliance(permit) },
          overall_compliance: calculate_overall_compliance(permits),
          recommendations: generate_project_recommendations(permits)
        }
        
        @report_data = compliance_data
        compliance_data
      end

      # Export timeline report
      def export_timeline_report(format: :pdf)
        timeline_data = generate_comprehensive_timeline
        @report_data = timeline_data
        
        generate_report(format: format, title: "Timeline Permis - #{@project.name}")
      end

      private

      # Implement build_report_data from Reportable concern
      def build_report_data
        generate_comprehensive_timeline
      end

      def calculate_processing_statistics
        approved_permits = @project.permits.approved.where.not(submitted_date: nil, approved_date: nil)
        
        return empty_processing_stats if approved_permits.empty?
        
        processing_times = {}
        all_times = []
        
        approved_permits.group_by(&:permit_type).each do |type, permits|
          times = permits.map { |p| calculate_business_days(p.submitted_date, p.approved_date) }
          processing_times[type.to_sym] = {
            average: times.sum.to_f / times.size,
            median: calculate_median(times),
            min: times.min,
            max: times.max,
            count: times.size
          }
          all_times.concat(times)
        end
        
        {
          by_type: processing_times,
          overall: {
            average: all_times.sum.to_f / all_times.size,
            total_permits: all_times.size
          }
        }
      end

      def calculate_duration_estimates
        permit_types = determine_required_permits(@project)
        
        estimates = {}
        
        permit_types.each do |permit_type|
          estimates[permit_type] = estimate_permit_duration(permit_type, @project.complexity_level)
        end
        
        estimates
      end

      def calculate_overall_compliance(permits)
        return { score: 0, status: :unknown } if permits.empty?
        
        compliance_scores = permits.map do |permit|
          result = check_permit_compliance(permit)
          result[:compliance_score] || 0
        end
        
        overall_score = compliance_scores.sum.to_f / compliance_scores.size
        
        {
          score: overall_score,
          status: compliance_status_from_score(overall_score),
          compliant_permits: compliance_scores.count { |score| score >= 0.8 },
          total_permits: permits.size
        }
      end

      def generate_project_recommendations(permits)
        recommendations = []
        
        permits.each do |permit|
          compliance = check_permit_compliance(permit)
          recommendations.concat(compliance[:recommendations]) unless compliance[:overall_compliant]
        end
        
        # Add project-level recommendations
        if permits.any? { |p| !permit_on_track?(p) }
          recommendations << "Réviser le planning global des permis"
        end
        
        critical_path = analyze_critical_path(@project)
        if critical_path[:bottlenecks].present?
          recommendations << "Traiter les goulots d'étranglement identifiés"
        end
        
        recommendations.uniq
      end

      def empty_processing_stats
        {
          by_type: {},
          overall: { average: 0, total_permits: 0 }
        }
      end

      def compliance_status_from_score(score)
        case score
        when 0.9..1.0 then :excellent
        when 0.8..0.9 then :good
        when 0.6..0.8 then :acceptable
        when 0.4..0.6 then :poor
        else :critical
        end
      end

      def project_summary(project)
        {
          id: project.id,
          name: project.name,
          status: project.status,
          complexity_level: project.complexity_level,
          total_permits: project.permits.count,
          progress: calculate_project_progress(project)
        }
      end

      def calculate_median(values)
        return 0 if values.empty?
        
        sorted = values.sort
        size = sorted.size
        
        if size.even?
          (sorted[size / 2 - 1] + sorted[size / 2]).to_f / 2
        else
          sorted[size / 2].to_f
        end
      end

      # Project-specific methods for permit requirements
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
    end
  end
end