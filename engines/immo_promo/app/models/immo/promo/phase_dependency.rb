class Immo::Promo::PhaseDependency < ApplicationRecord
  self.table_name = 'immo_promo_phase_dependencies'
  
  belongs_to :prerequisite_phase, class_name: 'Immo::Promo::Phase'
  belongs_to :dependent_phase, class_name: 'Immo::Promo::Phase'

  validates :prerequisite_phase_id, uniqueness: { scope: :dependent_phase_id }
  validate :no_circular_dependency
  validate :phases_in_same_project

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
    return unless prerequisite_phase && dependent_phase
    
    if prerequisite_phase_id == dependent_phase_id
      errors.add(:base, 'A phase cannot depend on itself')
      return
    end

    # Check for circular dependencies using a simple traversal
    visited = Set.new
    queue = [dependent_phase_id]
    
    while queue.any?
      current_id = queue.shift
      next if visited.include?(current_id)
      visited.add(current_id)
      
      if current_id == prerequisite_phase_id
        errors.add(:base, 'This dependency would create a circular reference')
        break
      end
      
      # Add all phases that depend on the current phase
      Immo::Promo::PhaseDependency.where(prerequisite_phase_id: current_id).pluck(:dependent_phase_id).each do |dep_id|
        queue << dep_id unless visited.include?(dep_id)
      end
    end
  end

  def phases_in_same_project
    return unless prerequisite_phase && dependent_phase
    
    if prerequisite_phase.project_id != dependent_phase.project_id
      errors.add(:base, 'Phases must belong to the same project')
    end
  end
end