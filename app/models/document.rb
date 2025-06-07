class Document < ApplicationRecord
  include AASM
  
  belongs_to :user
  belongs_to :parent, class_name: 'Document', optional: true
  belongs_to :space
  belongs_to :folder, optional: true
  
  has_many :children, class_name: 'Document', foreign_key: 'parent_id', dependent: :destroy
  has_many :shares, dependent: :destroy
  has_many :shared_users, through: :shares, source: :user
  has_many :document_versions, dependent: :destroy
  has_many :metadata, class_name: 'Metadatum', as: :metadatable, dependent: :destroy
  has_many :document_tags, dependent: :destroy
  has_many :tags, through: :document_tags
  has_many :workflow_submissions, as: :submittable, dependent: :destroy
  has_many :workflows, through: :workflow_submissions
  has_many :links, dependent: :destroy
  has_many :linked_documents, through: :links, source: :linked_document
  
  has_one_attached :file
  
  validates :title, presence: true
  validates :file, presence: true
  
  searchkick word_start: [:title, :description], 
             searchable: [:title, :description, :content, :metadata_text],
             filterable: [:document_type, :created_at, :user_id, :space_id, :tags]
  
  audited
  has_paper_trail
  
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
  
  SUPPORTED_FORMATS = {
    pdf: ['application/pdf'],
    word: ['application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'],
    excel: ['application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'],
    powerpoint: ['application/vnd.ms-powerpoint', 'application/vnd.openxmlformats-officedocument.presentationml.presentation'],
    image: ['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml'],
    audio: ['audio/mpeg', 'audio/wav', 'audio/ogg', 'audio/webm'],
    video: ['video/mp4', 'video/webm', 'video/ogg'],
    mail: ['message/rfc822'],
    zip: ['application/zip', 'application/x-zip-compressed']
  }.freeze
  
  def supported_format?
    SUPPORTED_FORMATS.values.flatten.include?(file.blob.content_type)
  end
  
  def document_type
    SUPPORTED_FORMATS.each do |type, formats|
      return type.to_s if formats.include?(file.blob.content_type)
    end
    'other'
  end
  
  def search_data
    {
      title: title,
      description: description,
      content: extracted_content,
      metadata_text: metadata_text,
      document_type: document_type,
      created_at: created_at,
      user_id: user_id,
      space_id: space_id,
      tags: tags.pluck(:name)
    }
  end
  
  def extracted_content
    # TODO: Implement content extraction from files
    ''
  end
  
  def metadata_text
    metadata.map { |m| "#{m.name}: #{m.value}" }.join(' ')
  end
end