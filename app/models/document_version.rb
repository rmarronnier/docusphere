class DocumentVersion < ApplicationRecord
  belongs_to :document
  belongs_to :created_by, class_name: 'User'
  
  has_one_attached :file
  
  validates :version_number, presence: true, uniqueness: { scope: :document_id }
  validates :file, presence: true
  validates :created_by, presence: true
  
  before_validation :set_version_number, on: :create
  after_create :update_document_current_version
  
  scope :latest_first, -> { order(version_number: :desc) }
  scope :oldest_first, -> { order(version_number: :asc) }
  
  def title
    "#{document.title} - v#{version_number}"
  end
  
  def is_current?
    document.current_version_number == version_number
  end
  
  def make_current!
    transaction do
      # Update document to point to this version
      document.update!(
        current_version_number: version_number,
        file: self.file.blob
      )
      
      # Log the version change
      document.audits.create!(
        action: 'version_change',
        audited_changes: {
          'current_version_number' => [document.current_version_number_was, version_number]
        },
        user: created_by,
        comment: "Restored to version #{version_number}"
      )
    end
  end
  
  def file_size
    file.blob.byte_size if file.attached?
  end
  
  def file_size_human
    return nil unless file.attached?
    
    size = file.blob.byte_size
    case
    when size < 1.kilobyte
      "#{size} B"
    when size < 1.megabyte
      "#{(size.to_f / 1.kilobyte).round(1)} KB"
    when size < 1.gigabyte
      "#{(size.to_f / 1.megabyte).round(1)} MB"
    else
      "#{(size.to_f / 1.gigabyte).round(1)} GB"
    end
  end
  
  def changes_from_previous
    previous = document.document_versions.where('version_number < ?', version_number).order(version_number: :desc).first
    return nil unless previous
    
    {
      file_size_change: file_size - previous.file_size,
      time_since_previous: created_at - previous.created_at
    }
  end
  
  private
  
  def set_version_number
    return if version_number.present?
    
    max_version = document.document_versions.maximum(:version_number) || 0
    self.version_number = max_version + 1
  end
  
  def update_document_current_version
    document.update_column(:current_version_number, version_number)
  end
end