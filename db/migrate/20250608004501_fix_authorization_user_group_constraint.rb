class FixAuthorizationUserGroupConstraint < ActiveRecord::Migration[7.1]
  def change
    # Make user_id and user_group_id nullable since only one should be present
    change_column_null :authorizations, :user_id, true
    change_column_null :authorizations, :user_group_id, true
    
    # Clean up existing invalid data - delete rows that have both or neither
    execute <<-SQL
      DELETE FROM authorizations 
      WHERE (user_id IS NOT NULL AND user_group_id IS NOT NULL) 
         OR (user_id IS NULL AND user_group_id IS NULL);
    SQL
    
    # Add check constraint to ensure exactly one is present
    execute <<-SQL
      ALTER TABLE authorizations 
      ADD CONSTRAINT check_user_or_group_present 
      CHECK (
        (user_id IS NOT NULL AND user_group_id IS NULL) OR 
        (user_id IS NULL AND user_group_id IS NOT NULL)
      );
    SQL
  end
end
