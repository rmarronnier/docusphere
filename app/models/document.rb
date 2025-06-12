class Document < ApplicationRecord
  include AASM
  include Authorizable
  include Linkable
  include Validatable
  include Documents::Lockable
  include Documents::AiProcessable
  include Documents::VirusScannable
  include Documents::Versionable
  include Documents::Processable
  include Documents::Searchable
  include Documents::FileManagement
  include Documents::Shareable
  include Documents::Taggable
  include Documents::DisplayHelpers
  include Documents::ActivityTrackable
  include Documents::ViewTrackable
  
  # Configure ownership
  owned_by :uploaded_by
  
  belongs_to :uploaded_by, class_name: 'User', foreign_key: 'uploaded_by_id'
  belongs_to :parent, class_name: 'Document', optional: true
  belongs_to :space
  belongs_to :folder, optional: true
  belongs_to :documentable, polymorphic: true, optional: true
  
  has_many :children, class_name: 'Document', foreign_key: 'parent_id', dependent: :destroy
  has_many :metadata, class_name: 'Metadatum', as: :metadatable, dependent: :destroy
  has_many :document_metadata, class_name: 'DocumentMetadata', dependent: :destroy
  
  belongs_to :locked_by, class_name: 'User', optional: true
  has_many :metadata_templates, through: :document_metadata
  has_many :source_links, class_name: 'Link', as: :source, dependent: :destroy
  has_many :target_links, class_name: 'Link', as: :target, dependent: :destroy
  
  validates :title, presence: true
  
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
end