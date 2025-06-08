class Immo::Promo::TaskDependency < ApplicationRecord
  self.table_name = 'immo_promo_task_dependencies'
  
  belongs_to :prerequisite_task, class_name: 'Immo::Promo::Task'
  belongs_to :dependent_task, class_name: 'Immo::Promo::Task'

  validates :prerequisite_task_id, uniqueness: { scope: :dependent_task_id }
  validate :no_circular_dependency
  validate :tasks_in_same_project

  enum dependency_type: {
    finish_to_start: 'finish_to_start',
    start_to_start: 'start_to_start', 
    finish_to_finish: 'finish_to_finish',
    start_to_finish: 'start_to_finish'
  }

  def lag_in_days
    lag_days || 0
  end

  private

  def no_circular_dependency
    return unless prerequisite_task && dependent_task
    
    if prerequisite_task_id == dependent_task_id
      errors.add(:base, 'A task cannot depend on itself')
      return
    end

    # Check for circular dependencies
    visited = Set.new
    queue = [dependent_task_id]
    
    while queue.any?
      current_id = queue.shift
      next if visited.include?(current_id)
      visited.add(current_id)
      
      if current_id == prerequisite_task_id
        errors.add(:base, 'This dependency would create a circular reference')
        break
      end
      
      # Add all tasks that depend on the current task
      self.class.where(prerequisite_task_id: current_id).pluck(:dependent_task_id).each do |dep_id|
        queue << dep_id unless visited.include?(dep_id)
      end
    end
  end

  def tasks_in_same_project
    return unless prerequisite_task && dependent_task
    
    if prerequisite_task.project != dependent_task.project
      errors.add(:base, 'Tasks must belong to the same project')
    end
  end
end