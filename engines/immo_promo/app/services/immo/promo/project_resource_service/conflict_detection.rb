module Immo
  module Promo
    class ProjectResourceService
      module ConflictDetection
        def resource_conflict_calendar
          conflicts = []
          
          project.stakeholders.each do |stakeholder|
            stakeholder_conflicts = find_scheduling_conflicts(stakeholder)
            
            if stakeholder_conflicts.any?
              conflicts << {
                stakeholder: stakeholder,
                conflicts: stakeholder_conflicts,
                impact: assess_conflict_impact(stakeholder_conflicts)
              }
            end
          end
          
          {
            total_conflicts: conflicts.sum { |c| c[:conflicts].count },
            affected_resources: conflicts.count,
            conflicts_by_resource: conflicts,
            resolution_suggestions: generate_conflict_resolutions(conflicts)
          }
        end

        def identify_resource_conflicts
          conflicts = []
          
          # Overallocation conflicts
          overloaded = project.stakeholders.select { |s| calculate_utilization_percentage(s) > 100 }
          if overloaded.any?
            conflicts << {
              type: 'overallocation',
              severity: 'high',
              resources: overloaded,
              message: "#{overloaded.count} resources are overallocated"
            }
          end
          
          # Skill mismatch conflicts
          skill_mismatches = identify_skill_mismatches
          if skill_mismatches.any?
            conflicts << {
              type: 'skill_mismatch',
              severity: 'medium',
              count: skill_mismatches.count,
              message: "#{skill_mismatches.count} tasks assigned to resources without required skills"
            }
          end
          
          # Availability conflicts
          availability_conflicts = identify_availability_conflicts
          if availability_conflicts.any?
            conflicts << {
              type: 'availability',
              severity: 'high',
              count: availability_conflicts.count,
              message: "#{availability_conflicts.count} resources have scheduling conflicts"
            }
          end
          
          conflicts
        end

        private

        def find_scheduling_conflicts(stakeholder)
          conflicts = []
          tasks = stakeholder.tasks.where(status: ['in_progress', 'pending']).order(:start_date)
          
          tasks.each_with_index do |task, index|
            tasks[(index + 1)..-1].each do |other_task|
              if tasks_overlap?(task, other_task)
                conflicts << {
                  tasks: [task, other_task],
                  overlap_days: calculate_overlap_days(task, other_task),
                  severity: assess_overlap_severity(task, other_task)
                }
              end
            end
          end
          
          conflicts
        end

        def identify_skill_mismatches
          mismatches = []
          
          project.tasks.includes(:stakeholder).where.not(stakeholder_id: nil).each do |task|
            next if task.required_skills.blank?
            
            stakeholder_skills = task.stakeholder.certifications.pluck(:certification_type)
            missing_skills = task.required_skills - stakeholder_skills
            
            if missing_skills.any?
              mismatches << {
                task: task,
                stakeholder: task.stakeholder,
                missing_skills: missing_skills
              }
            end
          end
          
          mismatches
        end

        def identify_availability_conflicts
          conflicts = []
          
          project.stakeholders.each do |stakeholder|
            overlapping_tasks = find_overlapping_tasks(stakeholder)
            
            if overlapping_tasks.any?
              conflicts << {
                stakeholder: stakeholder,
                overlapping_tasks: overlapping_tasks
              }
            end
          end
          
          conflicts
        end

        def find_overlapping_tasks(stakeholder)
          tasks = stakeholder.tasks
                            .where(status: ['in_progress', 'pending'])
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

        def calculate_overlap_days(task1, task2)
          overlap_start = [task1.start_date, task2.start_date].max
          overlap_end = [task1.end_date, task2.end_date].min
          (overlap_end - overlap_start + 1).to_i
        end

        def assess_overlap_severity(task1, task2)
          if task1.priority == 'critical' || task2.priority == 'critical'
            'high'
          elsif task1.priority == 'high' || task2.priority == 'high'
            'medium'
          else
            'low'
          end
        end

        def assess_conflict_impact(conflicts)
          high_severity = conflicts.count { |c| c[:severity] == 'high' }
          total_overlap_days = conflicts.sum { |c| c[:overlap_days] }
          
          {
            severity_distribution: conflicts.group_by { |c| c[:severity] }.transform_values(&:count),
            total_overlap_days: total_overlap_days,
            affected_tasks: conflicts.flat_map { |c| c[:tasks] }.uniq.count,
            risk_level: high_severity > 0 ? 'high' : 'medium'
          }
        end

        def generate_conflict_resolutions(conflicts)
          resolutions = []
          
          conflicts.each do |resource_conflict|
            resource_conflict[:conflicts].each do |conflict|
              resolutions << {
                stakeholder: resource_conflict[:stakeholder],
                conflict: conflict,
                options: [
                  "Reschedule #{conflict[:tasks].first.name} to avoid overlap",
                  "Assign #{conflict[:tasks].last.name} to another resource",
                  "Negotiate extended timeline for both tasks",
                  "Prioritize #{conflict[:tasks].max_by(&:priority).name} and delay the other"
                ]
              }
            end
          end
          
          resolutions
        end
      end
    end
  end
end