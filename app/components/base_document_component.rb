# Base component for all document-related components
class BaseDocumentComponent < ApplicationComponent
  include Accessible

  # Default icon mappings for file types
  DEFAULT_ICON_MAPPING = {
    # Documents
    'pdf' => 'file-pdf',
    'doc' => 'file-word',
    'docx' => 'file-word',
    'xls' => 'file-excel',
    'xlsx' => 'file-excel',
    'ppt' => 'file-powerpoint',
    'pptx' => 'file-powerpoint',
    'txt' => 'file-text',
    'rtf' => 'file-text',
    'odt' => 'file-text',
    
    # Images
    'jpg' => 'file-image',
    'jpeg' => 'file-image',
    'png' => 'file-image',
    'gif' => 'file-image',
    'svg' => 'file-image',
    'webp' => 'file-image',
    
    # Archives
    'zip' => 'file-archive',
    'rar' => 'file-archive',
    '7z' => 'file-archive',
    'tar' => 'file-archive',
    'gz' => 'file-archive',
    
    # Code
    'html' => 'file-code',
    'css' => 'file-code',
    'js' => 'file-code',
    'json' => 'file-code',
    'xml' => 'file-code',
    'yml' => 'file-code',
    'yaml' => 'file-code',
    
    # Media
    'mp3' => 'file-audio',
    'wav' => 'file-audio',
    'mp4' => 'file-video',
    'avi' => 'file-video',
    'mov' => 'file-video',
    
    # Other
    'csv' => 'file-csv',
    'default' => 'file'
  }.freeze

  # Default status configurations
  DEFAULT_STATUS_CONFIG = {
    draft: { color: 'gray', label: 'Brouillon' },
    published: { color: 'green', label: 'Publié' },
    locked: { color: 'red', label: 'Verrouillé' },
    archived: { color: 'gray', label: 'Archivé' },
    processing: { color: 'yellow', label: 'En traitement' },
    completed: { color: 'green', label: 'Traité' },
    failed: { color: 'red', label: 'Échec' }
  }.freeze

  def initialize(document:, **options)
    @document = document
    @options = options
    @show_status = options.fetch(:show_status, true)
    @show_metadata = options.fetch(:show_metadata, true)
    @show_actions = options.fetch(:show_actions, true)
    @show_preview = options.fetch(:show_preview, false)
    @clickable = options.fetch(:clickable, true)
  end

  protected

  # Get icon for document type
  def document_icon
    return icon_mapping['default'] unless @document.file.attached?
    
    extension = @document.file_extension&.delete('.')&.downcase
    icon_mapping[extension] || icon_mapping['default']
  end

  # Get icon mapping (can be overridden in subclasses)
  def icon_mapping
    DEFAULT_ICON_MAPPING
  end

  # Get document status configuration
  def status_config
    status = @document.status&.to_sym || :draft
    status_configuration[status] || { color: 'gray', label: status.to_s.humanize }
  end

  # Get status configuration (can be overridden in subclasses)
  def status_configuration
    DEFAULT_STATUS_CONFIG
  end

  # Render document icon
  def render_document_icon
    render Ui::IconComponent.new(
      name: document_icon,
      size: icon_size,
      css_class: icon_classes
    )
  end

  # Render document status
  def render_document_status
    return unless @show_status && @document.respond_to?(:status)
    
    config = status_config
    render BaseStatusComponent.new(
      status: @document.status,
      label: config[:label],
      color: config[:color],
      size: status_size
    )
  end

  # Render document metadata
  def render_document_metadata
    return unless @show_metadata
    
    content_tag :div, class: 'text-sm text-gray-500' do
      safe_join([
        render_file_size,
        render_upload_info,
        render_tags
      ].compact, ' • ')
    end
  end

  # Render file size
  def render_file_size
    return unless @document.respond_to?(:human_file_size)
    @document.human_file_size
  end

  # Render upload info
  def render_upload_info
    return unless @document.respond_to?(:uploaded_by) && @document.uploaded_by
    
    time_ago = time_ago_in_words(@document.created_at)
    uploader = @document.uploaded_by.full_name
    
    "Ajouté #{time_ago} par #{uploader}"
  end

  # Render document tags
  def render_tags
    return unless @document.respond_to?(:tags) && @document.tags.any?
    
    content_tag :div, class: 'inline-flex gap-1' do
      safe_join(@document.tags.limit(3).map { |tag| render_tag(tag) })
    end
  end

  # Render individual tag
  def render_tag(tag)
    content_tag :span, 
                tag.name,
                class: 'inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800'
  end

  # Get document URL
  def document_url
    return '#' unless @clickable
    
    # Simple URL construction for tests and before rendering
    "/ged/document/#{@document.id}"
  end

  # Get preview URL
  def preview_url
    return unless @document.respond_to?(:preview) && @document.preview.attached?
    # Return a simple URL for testing
    "/preview/#{@document.id}"
  end

  # Check if document has preview
  def has_preview?
    @document.respond_to?(:preview) && @document.preview.attached?
  end

  # Default sizes (can be overridden)
  def icon_size
    :default
  end

  def status_size
    :default
  end

  def icon_classes
    'text-gray-400'
  end

  # Permission helpers
  def can_view?
    return true unless @document.respond_to?(:readable_by?)
    @document.readable_by?(Current.user)
  end

  def can_edit?
    return false unless @document.respond_to?(:writable_by?)
    @document.writable_by?(Current.user)
  end

  def can_delete?
    return false unless @document.respond_to?(:admin_by?)
    @document.admin_by?(Current.user)
  end

  # Processing status helpers
  def processing?
    @document.respond_to?(:processing_status) && 
    @document.processing_status == 'processing'
  end
  
  alias processing_processing? processing?

  def processing_failed?
    @document.respond_to?(:processing_status) && 
    @document.processing_status == 'failed'
  end

  def processing_completed?
    @document.respond_to?(:processing_status) && 
    @document.processing_status == 'completed'
  end

  # Lock status helpers
  def locked?
    @document.respond_to?(:locked?) && @document.locked?
  end

  def locked_by_current_user?
    locked? && @document.locked_by == Current.user
  end

  def lock_info
    return unless locked?
    
    {
      locked_by: @document.locked_by.full_name,
      locked_at: @document.locked_at,
      reason: @document.lock_reason
    }
  end
end