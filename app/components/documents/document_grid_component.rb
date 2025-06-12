class Documents::DocumentGridComponent < ApplicationComponent
  def initialize(documents:, view_mode: :grid, show_actions: true, selectable: false, **options)
    @documents = documents
    @view_mode = view_mode # :grid, :list, :compact
    @show_actions = show_actions
    @selectable = selectable
    @options = options
  end

  private

  attr_reader :documents, :view_mode, :show_actions, :selectable, :options

  def wrapper_classes
    classes = []
    
    case view_mode
    when :grid
      classes << "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4"
    when :list
      classes << "space-y-3"
    when :compact
      classes << "divide-y divide-gray-200"
    end
    
    classes << options[:class] if options[:class]
    classes.join(" ")
  end

  def document_icon(document)
    extension = document.file_extension&.delete('.')&.downcase
    
    case extension
    when 'pdf'
      { name: 'document-text', color: 'text-red-500' }
    when 'doc', 'docx'
      { name: 'document', color: 'text-blue-500' }
    when 'xls', 'xlsx'
      { name: 'table', color: 'text-green-500' }
    when 'ppt', 'pptx'
      { name: 'presentation-chart-bar', color: 'text-orange-500' }
    when 'jpg', 'jpeg', 'png', 'gif', 'webp'
      { name: 'photograph', color: 'text-purple-500' }
    when 'mp4', 'mov', 'avi'
      { name: 'film', color: 'text-pink-500' }
    when 'mp3', 'wav', 'flac'
      { name: 'music-note', color: 'text-indigo-500' }
    when 'zip', 'rar', '7z'
      { name: 'archive', color: 'text-gray-500' }
    else
      { name: 'document', color: 'text-gray-400' }
    end
  end

  def file_size_color(size)
    case
    when size < 1.megabyte
      'text-green-600'
    when size < 10.megabytes
      'text-yellow-600'
    when size < 100.megabytes
      'text-orange-600'
    else
      'text-red-600'
    end
  end

  def preview_available?(document)
    return false unless document.file.attached?
    
    extension = document.file_extension&.delete('.')&.downcase
    ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf'].include?(extension)
  end

  def thumbnail_url(document)
    return helpers.asset_path('document-placeholder.png') unless document.respond_to?(:file) && document.file&.attached?
    
    # Utiliser la vraie vignette si elle existe
    if document.respond_to?(:has_thumbnail?) && document.has_thumbnail?
      helpers.rails_blob_path(document.thumbnail)
    elsif document.respond_to?(:preview) && document.preview&.attached?
      # Fallback sur preview si pas de thumbnail
      helpers.rails_blob_path(document.preview)
    elsif document.respond_to?(:image?) && document.image?
      # Pour les images, utiliser le fichier directement avec variant
      helpers.rails_representation_path(document.file.variant(resize_to_limit: [200, 200]))
    else
      # Icône fallback selon le type de fichier
      icon_path_for_document(document)
    end
  rescue => e
    Rails.logger.error "Error generating thumbnail URL for document #{document.id}: #{e.message}" if Rails.env.development?
    icon_path_for_document(document)
  end

  def icon_path_for_document(document)
    extension = document.file_extension&.delete('.')&.downcase
    icon_name = case extension
                when 'pdf' then 'pdf-icon.svg'
                when 'doc', 'docx' then 'word-icon.svg'
                when 'xls', 'xlsx' then 'excel-icon.svg'
                when 'ppt', 'pptx' then 'ppt-icon.svg'
                when 'zip', 'rar', '7z' then 'zip-icon.svg'
                when 'txt', 'md' then 'txt-icon.svg'
                else 'generic-icon.svg'
                end
    
    helpers.asset_path("file-icons/#{icon_name}")
  end

  def preview_url(document, variant = :medium)
    return nil unless document.respond_to?(:file) && document.file&.attached?
    
    if document.respond_to?(:preview) && document.preview&.attached?
      helpers.rails_blob_path(document.preview)
    elsif document.respond_to?(:preview_medium) && document.preview_medium&.attached? && variant == :medium
      helpers.rails_blob_path(document.preview_medium)
    elsif document.respond_to?(:image?) && document.image?
      dimensions = case variant
                   when :thumbnail then [200, 200]
                   when :medium then [800, 600]
                   when :large then [1200, 900]
                   else [800, 600]
                   end
      helpers.rails_representation_path(document.file.variant(resize_to_limit: dimensions))
    else
      nil
    end
  rescue => e
    Rails.logger.error "Error generating preview URL for document #{document.id}: #{e.message}" if Rails.env.development?
    nil
  end

  def preview_document_path(document)
    # For now, return the document path itself
    # Later we can add a specific preview route
    helpers.ged_document_path(document)
  end
end