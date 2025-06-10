class Document < ApplicationRecord
  include AASM
  include Authorizable
  include Linkable
  include Validatable
  include Document::Lockable
  include Document::AiProcessable
  include Document::VirusScannable
  include Document::Versionable
  include Document::Processable
  
  # Configure ownership
  owned_by :uploaded_by
  
  belongs_to :uploaded_by, class_name: 'User', foreign_key: 'uploaded_by_id'
  belongs_to :parent, class_name: 'Document', optional: true
  belongs_to :space
  belongs_to :folder, optional: true
  belongs_to :documentable, polymorphic: true, optional: true
  
  has_many :children, class_name: 'Document', foreign_key: 'parent_id', dependent: :destroy
  has_many :shares, as: :shareable, dependent: :destroy
  has_many :document_shares, dependent: :destroy
  has_many :metadata, class_name: 'Metadatum', as: :metadatable, dependent: :destroy
  has_many :document_tags, dependent: :destroy
  has_many :tags, through: :document_tags
  has_many :source_links, class_name: 'Link', as: :source, dependent: :destroy
  has_many :target_links, class_name: 'Link', as: :target, dependent: :destroy
  
  has_one_attached :file
  has_one_attached :preview
  has_one_attached :thumbnail
  
  validates :title, presence: true
  validates :file, presence: true
  validates :file_size, numericality: { less_than_or_equal_to: 100.megabytes }, if: :file_attached?
  
  searchkick word_start: [:title, :description], 
             searchable: [:title, :description, :content, :metadata_text],
             filterable: [:document_type, :document_category, :documentable_type, :created_at, :user_id, :space_id, :tags]
  
  audited
  
  aasm column: 'status' do
    state :draft, initial: true
    state :published
    state :locked
    state :archived
    state :marked_for_deletion
    state :deleted
    
    event :publish do
      transitions from: :draft, to: :published
    end
    
    event :lock do
      transitions from: [:draft, :published], to: :locked
      before do
        self.locked_at = Time.current
      end
    end
    
    event :unlock do
      transitions from: :locked, to: :published
      before do
        self.locked_by = nil
        self.locked_at = nil
        self.lock_reason = nil
        self.unlock_scheduled_at = nil
      end
    end
    
    event :archive do
      transitions from: [:published, :locked], to: :archived
    end
    
    event :mark_for_deletion do
      transitions from: [:published, :locked, :archived], to: :marked_for_deletion
    end
    
    event :soft_delete do
      transitions from: :marked_for_deletion, to: :deleted
    end
  end
  
  # Search data for Elasticsearch
  def search_data
    {
      title: title,
      description: description,
      content: extracted_content,
      metadata_text: metadata_text,
      document_type: document_type,
      document_category: document_category,
      documentable_type: documentable_type,
      created_at: created_at,
      user_id: uploaded_by_id,
      space_id: space_id,
      tags: tags.pluck(:name)
    }
  end
  
  # Metadata text for search
  def metadata_text
    metadata.map { |m| "#{m.name}: #{m.value}" }.join(' ')
  end
  
  # File validation helper
  def file_attached?
    file.attached?
  end
  
  # Get file size in bytes
  def file_size
    file.blob.byte_size if file.attached?
  end
  
  
  def can_request_validation?(user)
    return false unless user
    return false if validation_pending?
    
    # Owner can always request validation
    return true if self.uploaded_by == user
    
    # Admin can request validation
    return true if admin_by?(user)
    
    # Users with write permission can request validation
    writable_by?(user)
  end
  
  # Validation summary
  def validation_summary
    return nil unless current_validation_request
    
    {
      status: validation_status,
      progress: current_validation_request.validation_progress,
      requester: current_validation_request.requester.full_name,
      created_at: current_validation_request.created_at,
      completed_at: current_validation_request.completed_at
    }
  end
  
  # Display helpers
  def display_name
    title
  end
  
  def file_extension
    return nil unless file.attached?
    File.extname(file.filename.to_s).downcase
  end
  
  def file_name_without_extension
    return nil unless file.attached?
    File.basename(file.filename.to_s, file_extension)
  end
  
  def human_file_size
    return nil unless file_size
    
    if file_size < 1024
      "#{file_size} B"
    elsif file_size < 1024 * 1024
      "#{(file_size / 1024.0).round(1)} KB"
    elsif file_size < 1024 * 1024 * 1024
      "#{(file_size / (1024.0 * 1024)).round(1)} MB"
    else
      "#{(file_size / (1024.0 * 1024 * 1024)).round(2)} GB"
    end
  end
  
  # Path helpers
  def full_path
    return "/#{title}" unless folder
    "#{folder.full_path}/#{title}"
  end
  
  def breadcrumb_items
    items = []
    items << { name: space.name, path: space }
    
    if folder
      folder.ancestors.each do |ancestor|
        items << { name: ancestor.name, path: ancestor }
      end
      items << { name: folder.name, path: folder }
    end
    
    items << { name: title, path: self }
    items
  end
  
  # Activity tracking
  def track_view!(user)
    increment!(:view_count)
    # Could also create an activity record here
  end
  
  def track_download!(user)
    increment!(:download_count)
    # Could also create an activity record here
  end
  
  # Sharing helpers
  def shared_with?(user)
    return false unless user
    document_shares.active.where(shared_with: user).exists?
  end
  
  def share_with!(user, access_level: 'read', expires_at: nil, shared_by: nil)
    document_shares.create!(
      shared_with: user,
      shared_by: shared_by || Current.user,
      access_level: access_level,
      expires_at: expires_at
    )
  end
  
  # Tag helpers
  def tag_list
    tags.pluck(:name).join(', ')
  end
  
  def tag_list=(names)
    self.tags = names.split(',').map(&:strip).uniq.map do |name|
      Tag.find_or_create_by(name: name, organization: space.organization)
    end
  end
end