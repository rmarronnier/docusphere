module Immo
  module Promo
    module ProjectsHelper
      # Helper methods for projects and coordination

      def certification_status_color(certifications_status)
        critical_count = certifications_status.count { |cs| cs[:status] == 'critical' }
        warning_count = certifications_status.count { |cs| cs[:status] == 'warning' }
        
        if critical_count > 0
          'h-8 w-8 text-red-600'
        elsif warning_count > 0
          'h-8 w-8 text-yellow-600'
        else
          'h-8 w-8 text-green-600'
        end
      end

      def compliant_stakeholders_count(certifications_status)
        certifications_status.count { |cs| cs[:status] == 'valid' }
      end

      def critical_certifications?(certifications_status)
        certifications_status.any? { |cs| cs[:status] == 'critical' }
      end

      def project_status_badge(status)
        case status.to_s
        when 'planning'
          { color: 'blue', text: 'En planification' }
        when 'in_progress'
          { color: 'green', text: 'En cours' }
        when 'on_hold'
          { color: 'yellow', text: 'En pause' }
        when 'completed'
          { color: 'gray', text: 'Terminé' }
        when 'cancelled'
          { color: 'red', text: 'Annulé' }
        else
          { color: 'gray', text: status.humanize }
        end
      end

      def phase_status_icon(phase)
        if phase.start_date > Date.current
          'clock'
        elsif phase.end_date < Date.current
          'check-circle'
        else
          'play'
        end
      end

      def phase_progress_color(phase)
        progress = calculate_phase_progress(phase)
        
        if progress < 30
          'bg-red-500'
        elsif progress < 70
          'bg-yellow-500'
        else
          'bg-green-500'
        end
      end

      def task_priority_badge(priority)
        case priority.to_s
        when 'low'
          { color: 'gray', text: 'Faible' }
        when 'medium'
          { color: 'yellow', text: 'Normale' }
        when 'high'
          { color: 'red', text: 'Élevée' }
        when 'urgent'
          { color: 'red', text: 'Urgente', extra_classes: 'font-bold' }
        else
          { color: 'gray', text: priority.humanize }
        end
      end

      def stakeholder_role_icon(role)
        {
          'architect' => 'building-office',
          'engineer' => 'wrench-screwdriver',
          'contractor' => 'hammer',
          'electrician' => 'bolt',
          'plumber' => 'wrench',
          'project_manager' => 'user-circle',
          'client' => 'user',
          'supplier' => 'truck'
        }[role.to_s] || 'user'
      end

      def performance_score_color(score)
        if score >= 80
          'text-green-600'
        elsif score >= 60
          'text-yellow-600'
        else
          'text-red-600'
        end
      end

      def conflict_severity_badge(severity)
        case severity.to_s
        when 'low'
          { color: 'yellow', text: 'Faible' }
        when 'medium'
          { color: 'orange', text: 'Modéré' }
        when 'high'
          { color: 'red', text: 'Élevé' }
        when 'critical'
          { color: 'red', text: 'Critique', extra_classes: 'font-bold' }
        else
          { color: 'gray', text: severity.humanize }
        end
      end

      def format_duration(hours)
        if hours < 24
          "#{hours}h"
        elsif hours < 168 # 7 jours
          "#{(hours / 24.0).round(1)}j"
        else
          "#{(hours / 168.0).round(1)}sem"
        end
      end

      def days_until_deadline(date)
        return 0 if date.nil?
        
        days = (date.to_date - Date.current).to_i
        days > 0 ? days : 0
      end

      def deadline_urgency_class(date)
        return 'text-gray-500' if date.nil?
        
        days = days_until_deadline(date)
        
        if days == 0
          'text-red-600 font-bold'
        elsif days <= 3
          'text-red-600'
        elsif days <= 7
          'text-yellow-600'
        else
          'text-gray-700'
        end
      end

      private

      def calculate_phase_progress(phase)
        return 0 if phase.tasks.empty?
        
        completed_tasks = phase.tasks.where(status: 'completed').count
        total_tasks = phase.tasks.count
        
        (completed_tasks.to_f / total_tasks * 100).round
      end

      # Risk monitoring helpers
      def determine_overall_risk_level
        critical_count = @project.risks.where(severity: 'critical', status: 'active').count if @project
        high_count = @project.risks.where(severity: 'high', status: 'active').count if @project
        
        if critical_count && critical_count > 0
          'critical'
        elsif high_count && high_count > 3
          'high'
        elsif high_count && high_count > 0
          'medium'
        else
          'low'
        end
      end

      def calculate_mitigation_percentage
        return 0 unless @mitigation_status
        
        total_actions = @mitigation_status[:total_actions] || 0
        return 0 if total_actions.zero?
        
        completed = @mitigation_status[:completed] || 0
        (completed.to_f / total_actions * 100).round
      end

      def matrix_cell_color(probability, impact)
        # Scoring pour déterminer la couleur
        prob_scores = { 'very_low' => 1, 'low' => 2, 'medium' => 3, 'high' => 4, 'very_high' => 5 }
        impact_scores = { 'negligible' => 1, 'minor' => 2, 'moderate' => 3, 'major' => 4, 'catastrophic' => 5 }
        
        score = (prob_scores[probability] || 3) * (impact_scores[impact] || 3)
        
        case score
        when 1..4
          'bg-green-500'
        when 5..9
          'bg-yellow-500'
        when 10..15
          'bg-orange-500'
        else
          'bg-red-600'
        end
      end

      def risk_category_icon(category)
        {
          'technical' => 'wrench-screwdriver',
          'financial' => 'banknotes',
          'schedule' => 'calendar',
          'regulatory' => 'scale',
          'environmental' => 'globe-alt',
          'contractual' => 'document-text',
          'organizational' => 'user-group'
        }[category.to_s] || 'exclamation-triangle'
      end

      def risk_category_color(category)
        {
          'technical' => 'blue',
          'financial' => 'green',
          'schedule' => 'yellow',
          'regulatory' => 'red',
          'environmental' => 'teal',
          'contractual' => 'purple',
          'organizational' => 'gray'
        }[category.to_s] || 'gray'
      end
    end
  end
end