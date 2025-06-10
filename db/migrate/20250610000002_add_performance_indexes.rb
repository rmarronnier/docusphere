class AddPerformanceIndexes < ActiveRecord::Migration[7.1]
  def change
    # Index pour améliorer les requêtes d'autorisation
    unless index_exists?(:authorizations, [:authorizable_type, :authorizable_id, :user_id])
      add_index :authorizations, [:authorizable_type, :authorizable_id, :user_id], 
                name: 'index_authorizations_on_authorizable_and_user'
    end
    
    unless index_exists?(:authorizations, [:authorizable_type, :authorizable_id, :user_group_id])
      add_index :authorizations, [:authorizable_type, :authorizable_id, :user_group_id], 
                name: 'index_authorizations_on_authorizable_and_group'
    end
    
    # Index pour améliorer les requêtes de documents
    unless index_exists?(:documents, [:space_id, :status])
      add_index :documents, [:space_id, :status]
    end
    
    # Index pour améliorer les requêtes de validation
    unless index_exists?(:validation_requests, [:validatable_type, :validatable_id, :status])
      add_index :validation_requests, [:validatable_type, :validatable_id, :status],
                name: 'index_validation_requests_on_validatable_and_status'
    end
    
    unless index_exists?(:document_validations, [:validatable_type, :validatable_id, :status])
      add_index :document_validations, [:validatable_type, :validatable_id, :status],
                name: 'index_document_validations_on_validatable_and_status'
    end
    
    # Index pour améliorer les requêtes de notifications
    unless index_exists?(:notifications, [:user_id, :read_at])
      add_index :notifications, [:user_id, :read_at]
    end
    
    unless index_exists?(:notifications, [:notification_type, :created_at])
      add_index :notifications, [:notification_type, :created_at]
    end
    
    # Index pour améliorer les requêtes de folders
    unless index_exists?(:folders, [:space_id, :parent_id])
      add_index :folders, [:space_id, :parent_id]
    end
    
    # Index pour améliorer les requêtes de user_group_memberships
    unless index_exists?(:user_group_memberships, [:user_id, :role])
      add_index :user_group_memberships, [:user_id, :role]
    end
    
    # Index pour améliorer les requêtes de tags
    unless index_exists?(:document_tags, [:document_id, :tag_id], unique: true)
      add_index :document_tags, [:document_id, :tag_id], unique: true
    end
    
    # Note: tags table already has an index on [:organization_id, :name]
  end
end