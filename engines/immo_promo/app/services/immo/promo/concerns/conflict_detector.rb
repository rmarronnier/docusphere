module Immo
  module Promo
    module Concerns
      module ConflictDetector
        extend ActiveSupport::Concern

        def detect_conflicts
          {
            resource_conflicts: find_resource_conflicts,
            dependency_conflicts: find_dependency_conflicts,
            certification_conflicts: find_certification_conflicts
          }
        end

        def active_interventions
          project.tasks
                 .joins(:phase)
                 .where(status: ['in_progress', 'pending'])
                 .where('immo_promo_tasks.start_date <= ? AND immo_promo_tasks.end_date >= ?', Date.current, Date.current)
                 .includes(:assigned_to, :phase, :stakeholder)
        end

        def upcoming_interventions
          project.tasks
                 .joins(:phase)
                 .where(status: 'pending')
                 .where('immo_promo_tasks.start_date > ?', Date.current)
                 .where('immo_promo_tasks.start_date <= ?', Date.current + 2.weeks)
                 .includes(:assigned_to, :phase, :stakeholder)
                 .order(:start_date)
        end

        private

        def find_resource_conflicts
          conflicts = []
          
          project.stakeholders.each do |stakeholder|
            overlapping_tasks = find_overlapping_tasks(stakeholder)
            
            overlapping_tasks.each do |task_pair|
              conflicts << {
                type: 'double_booking',
                stakeholder: stakeholder,
                tasks: task_pair
              }
            end
          end
          
          conflicts
        end

        def find_dependency_conflicts
          []  # Simplified for now
        end

        def find_certification_conflicts
          conflicts = []
          
          project.tasks.each do |task|
            if task.required_skills.present? && task.stakeholder
              missing_skills = task.required_skills - task.stakeholder.certifications.pluck(:certification_type)
              
              if missing_skills.any?
                conflicts << {
                  type: 'missing_certification',
                  task: task,
                  stakeholder: task.stakeholder,
                  missing: missing_skills
                }
              end
            end
          end
          
          conflicts
        end

        def find_overlapping_tasks(stakeholder)
          tasks = stakeholder.tasks.where(status: ['pending', 'in_progress'])
                            .where.not(start_date: nil, end_date: nil)
                            .order(:start_date)
          
          overlapping = []
          
          tasks.each_with_index do |task, index|
            tasks[(index + 1)..-1].each do |other_task|
              if tasks_overlap?(task, other_task)
                overlapping << [task, other_task]
              end
            end
          end
          
          overlapping
        end

        def tasks_overlap?(task1, task2)
          task1.start_date <= task2.end_date && task1.end_date >= task2.start_date
        end
      end
    end
  end
end