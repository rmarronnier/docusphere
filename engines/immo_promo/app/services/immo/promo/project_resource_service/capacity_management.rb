module Immo
  module Promo
    class ProjectResourceService
      module CapacityManagement
        def resource_capacity_planning
          @capacity_service.analyze_capacity
        end

        def calculate_availability(stakeholder)
          total_capacity = 40 # hours per week
          allocated_hours = calculate_weekly_allocated_hours(stakeholder)
          
          {
            total_capacity: total_capacity,
            allocated_hours: allocated_hours,
            available_hours: total_capacity - allocated_hours,
            availability_percentage: ((total_capacity - allocated_hours) / total_capacity.to_f * 100).round(2),
            status: resource_status(allocated_hours / total_capacity.to_f * 100)
          }
        end

        private

        def calculate_weekly_allocated_hours(stakeholder)
          active_tasks = stakeholder.tasks.where(status: ['in_progress', 'pending'])
          return 0 if active_tasks.empty?
          
          weeks_remaining = @capacity_service.send(:calculate_weeks_remaining)
          return 40 if weeks_remaining == 0
          
          total_hours = active_tasks.sum(:estimated_hours)
          (total_hours.to_f / weeks_remaining).round(2)
        end

        def calculate_allocated_hours(stakeholder)
          stakeholder.tasks
                     .where(status: ['in_progress', 'pending'])
                     .sum(:estimated_hours)
        end

        def can_handle_task?(assignee, task)
          return false unless assignee

          # Check if assignee has required skills
          required_skills = task.required_skills || []
          return true if required_skills.empty?

          # For stakeholders, check certifications
          if assignee.is_a?(Immo::Promo::Stakeholder)
            stakeholder_skills = assignee.certifications.valid.pluck(:certification_type)
            return required_skills.all? { |skill| stakeholder_skills.include?(skill) }
          end

          # For users, assume they can handle basic tasks
          true
        end
      end
    end
  end
end