class AddWorkflowStatusToImmoPromoModels < ActiveRecord::Migration[7.1]
  def change
    # Add workflow_status column to models that use WorkflowManageable
    add_column :immo_promo_permits, :workflow_status, :string, default: 'pending'
    add_column :immo_promo_phases, :workflow_status, :string, default: 'pending'
    add_column :immo_promo_tasks, :workflow_status, :string, default: 'pending'
    
    # Add indexes for performance
    add_index :immo_promo_permits, :workflow_status
    add_index :immo_promo_phases, :workflow_status
    add_index :immo_promo_tasks, :workflow_status
    
    # Migrate existing status values to workflow_status
    reversible do |dir|
      dir.up do
        # For Phases and Tasks that have simple status
        execute <<-SQL
          UPDATE immo_promo_phases 
          SET workflow_status = CASE 
            WHEN status IN ('pending', 'in_progress', 'completed', 'cancelled') THEN status
            ELSE 'pending'
          END
        SQL
        
        execute <<-SQL
          UPDATE immo_promo_tasks 
          SET workflow_status = CASE 
            WHEN status IN ('pending', 'in_progress', 'completed', 'cancelled') THEN status
            ELSE 'pending'
          END
        SQL
        
        # For Permits, map their specific statuses to workflow statuses
        execute <<-SQL
          UPDATE immo_promo_permits 
          SET workflow_status = CASE 
            WHEN status IN ('draft', 'pending') THEN 'pending'
            WHEN status IN ('submitted', 'under_review', 'additional_info_requested') THEN 'in_progress'
            WHEN status = 'approved' THEN 'completed'
            WHEN status IN ('denied', 'appeal') THEN 'cancelled'
            ELSE 'pending'
          END
        SQL
      end
    end
  end
end