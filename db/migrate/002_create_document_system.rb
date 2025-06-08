class CreateDocumentSystem < ActiveRecord::Migration[7.1]
  def change
    # Create spaces table
    create_table :spaces do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.references :organization, null: false, foreign_key: true
      t.jsonb :settings, default: {}
      t.boolean :is_active, default: true
      t.timestamps
    end
    
    add_index :spaces, :is_active
    add_index :spaces, [:organization_id, :name], unique: true
    add_index :spaces, [:organization_id, :slug], unique: true
    
    # Create folders table
    create_table :folders do |t|
      t.string :name, null: false
      t.text :description
      t.references :space, null: false, foreign_key: true
      t.references :parent, foreign_key: { to_table: :folders }
      t.string :slug
      t.string :path
      t.integer :position
      t.jsonb :metadata, default: {}
      t.boolean :is_active, default: true
      t.timestamps
    end
    
    add_index :folders, :slug
    add_index :folders, :path
    add_index :folders, :position
    add_index :folders, :is_active
    
    # Create documents table
    create_table :documents do |t|
      t.string :title, null: false
      t.text :description
      t.references :folder, foreign_key: true
      t.references :space, null: false, foreign_key: true
      t.references :parent, foreign_key: { to_table: :documents }
      t.references :uploaded_by, null: false, foreign_key: { to_table: :users }
      t.string :document_type
      t.string :status, default: "draft"
      t.jsonb :metadata, default: {}
      t.integer :file_size
      t.string :content_type
      t.string :file_name
      t.datetime :archived_at
      t.boolean :is_template, default: false
      t.string :external_id
      t.datetime :expires_at
      t.boolean :is_public, default: false
      t.integer :download_count, default: 0
      t.integer :view_count, default: 0
      t.string :processing_status, default: "pending"
      t.string :virus_scan_status, default: "pending"
      t.text :content
      t.datetime :ai_processed_at
      t.string :ai_category
      t.timestamps
    end
    
    add_index :documents, :document_type
    add_index :documents, :status
    add_index :documents, :archived_at
    add_index :documents, :is_template
    add_index :documents, :external_id
    add_index :documents, :expires_at
    add_index :documents, :is_public
    add_index :documents, :processing_status
    add_index :documents, :virus_scan_status
    
    # Create tags table
    create_table :tags do |t|
      t.string :name, null: false
      t.string :color
      t.references :organization, null: false, foreign_key: true
      t.timestamps
    end
    
    add_index :tags, [:organization_id, :name], unique: true
    
    # Create document_tags join table
    create_table :document_tags do |t|
      t.references :document, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
      t.timestamps
    end
    
    add_index :document_tags, [:document_id, :tag_id], unique: true
    
    # Create document_versions table
    create_table :document_versions do |t|
      t.references :document, null: false, foreign_key: true
      t.integer :version_number, null: false
      t.references :uploaded_by, null: false, foreign_key: { to_table: :users }
      t.text :changes_description
      t.jsonb :metadata, default: {}
      t.timestamps
    end
    
    add_index :document_versions, [:document_id, :version_number], unique: true
    
    # Create document_shares table
    create_table :document_shares do |t|
      t.references :document, null: false, foreign_key: true
      t.references :shared_by, null: false, foreign_key: { to_table: :users }
      t.references :shared_with, foreign_key: { to_table: :users }
      t.string :email
      t.string :access_level, default: "read"
      t.datetime :expires_at
      t.string :access_token
      t.integer :access_count, default: 0
      t.datetime :last_accessed_at
      t.boolean :is_active, default: true
      t.timestamps
    end
    
    add_index :document_shares, :access_token, unique: true
    add_index :document_shares, :expires_at
    add_index :document_shares, :is_active
    
    # Create Active Storage tables
    create_table :active_storage_blobs do |t|
      t.string   :key,          null: false
      t.string   :filename,     null: false
      t.string   :content_type
      t.text     :metadata
      t.string   :service_name, null: false
      t.bigint   :byte_size,    null: false
      t.string   :checksum

      if connection.supports_datetime_with_precision?
        t.datetime :created_at, precision: 6, null: false
      else
        t.datetime :created_at, null: false
      end

      t.index [ :key ], unique: true
    end

    create_table :active_storage_attachments do |t|
      t.string     :name,     null: false
      t.references :record,   null: false, polymorphic: true, index: false
      t.references :blob,     null: false

      if connection.supports_datetime_with_precision?
        t.datetime :created_at, precision: 6, null: false
      else
        t.datetime :created_at, null: false
      end

      t.index [ :record_type, :record_id, :name, :blob_id ], name: :index_active_storage_attachments_uniqueness, unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
    end

    create_table :active_storage_variant_records do |t|
      t.belongs_to :blob, null: false, index: false, type: :bigint
      t.string :variation_digest, null: false

      t.index [ :blob_id, :variation_digest ], name: :index_active_storage_variant_records_uniqueness, unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
    end
  end
end