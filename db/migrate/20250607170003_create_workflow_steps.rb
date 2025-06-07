class CreateWorkflowSteps < ActiveRecord::Migration[7.1]
  def change
    create_table :workflow_steps do |t|
      t.references :workflow, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.string :step_type
      t.integer :position
      t.json :conditions
      t.json :actions

      t.timestamps
    end

    add_index :workflow_steps, :position
  end
end