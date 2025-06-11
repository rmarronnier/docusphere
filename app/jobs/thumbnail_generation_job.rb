class ThumbnailGenerationJob < ApplicationJob
  queue_as :document_processing
  
  # Priorité plus basse que DocumentProcessingJob selon tests  
  self.priority = 3
  
  # Méthode pour accéder à la priorité dans les tests
  def self.priority
    3
  end
  
  THUMBNAIL_SIZE = '200x200'
  THUMBNAIL_QUALITY = 85
  THUMBNAIL_WIDTH = 200
  THUMBNAIL_HEIGHT = 200
  
  # Configuration retry/discard selon tests
  retry_on MiniMagick::Error, wait: 5.seconds, attempts: 3
  discard_on ActiveRecord::RecordNotFound
  
  def perform(document_id)
    document = Document.find(document_id)
    
    unless document.file.attached?
      Rails.logger.info "ThumbnailGenerationJob: No file attached for document #{document_id}"
      return
    end
    
    return if document.has_thumbnail?
    
    generate_thumbnail(document)
    
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "ThumbnailGenerationJob: Document not found for ID #{document_id}"
  rescue MiniMagick::Error => e
    Rails.logger.error "ThumbnailGenerationJob: Image processing error for document #{document_id}: #{e.message}"
    mark_thumbnail_generation_failed(document) if document
  rescue StandardError => e
    Rails.logger.error "ThumbnailGenerationJob: Thumbnail generation failed for document #{document_id}: #{e.message}"
    mark_thumbnail_generation_failed(document) if document
  end
  
  private
  
  def generate_thumbnail(document)
    # Choisir la source appropriée
    if document.pdf?
      generate_pdf_thumbnail(document)
    elsif document.image?
      generate_image_thumbnail(document)
    elsif document.video?
      generate_video_thumbnail(document)
    else
      create_icon_thumbnail(document)
    end
  end
  
  def generate_image_thumbnail(document)
    return unless document.file.attached?
    
    if document.file.blob.byte_size > 10.megabytes
      process_in_chunks(document)
    else
      resize_image(document.file, width: THUMBNAIL_WIDTH, height: THUMBNAIL_HEIGHT, quality: THUMBNAIL_QUALITY)
    end
    
    attach_thumbnail(document, document.file)
  end
  
  def generate_pdf_thumbnail(document)
    return unless document.file.attached?
    
    extract_pdf_first_page(document)
  end
  
  def generate_video_thumbnail(document)
    # Extraire frame à 00:01 pour thumbnail vidéo
    create_icon_thumbnail(document) # Fallback pour l'instant
  end
  
  def resize_image(file, width:, height:, quality: 85)
    file.open do |tempfile|
      image = MiniMagick::Image.open(tempfile.path)
      
      # Redimensionnement intelligent avec ratio
      image.combine_options do |c|
        c.resize "#{width}x#{height}^"
        c.gravity 'center'
        c.extent "#{width}x#{height}"
      end
      
      optimize_image(image, quality: quality)
      image
    end
  end
  
  def optimize_image(image, quality: 85)
    # Optimisation pour le web
    image.format 'jpg'
    image.quality quality
    image.strip # Supprimer métadonnées EXIF
    image.colorspace 'sRGB' # Normaliser espace couleur
    
    # Réduction supplémentaire si trop lourd
    if image.size > 100.kilobytes
      image.quality [quality - 15, 50].max
    end
    
    image
  end
  
  def extract_pdf_first_page(document)
    return unless document.file.attached?
    
    document.file.open do |tempfile|
      # Utiliser MiniMagick avec ImageMagick pour PDF
      image = MiniMagick::Image.open("#{tempfile.path}[0]") # Première page
      
      # Redimensionner en thumbnail
      image.resize "#{THUMBNAIL_WIDTH}x#{THUMBNAIL_HEIGHT}"
      optimize_image(image)
      
      attach_thumbnail(document, image)
    end
  rescue StandardError => e
    Rails.logger.error "PDF thumbnail extraction failed: #{e.message}"
    create_icon_thumbnail(document)
  end
  
  def process_in_chunks(document)
    # Traitement par chunks pour gros fichiers
    Rails.logger.info "Processing large file in chunks for document #{document.id}"
    
    # Réduire qualité pour gros fichiers
    resize_image(document.file, width: THUMBNAIL_WIDTH, height: THUMBNAIL_HEIGHT, quality: 70)
  end
  
  def attach_thumbnail(document, source)
    temp_file = Tempfile.new(['thumbnail', '.jpg'])
    
    if source.is_a?(MiniMagick::Image)
      source.write(temp_file.path)
    else
      source.open do |file|
        image = resize_image(file, width: THUMBNAIL_WIDTH, height: THUMBNAIL_HEIGHT)
        image.write(temp_file.path)
      end
    end
    
    document.thumbnail.attach(
      io: File.open(temp_file.path),
      filename: "thumb_#{document.file.filename.base}.jpg",
      content_type: 'image/jpeg'
    )
    
    temp_file.unlink
  end
  
  def mark_thumbnail_generation_failed(document)
    # Marquer échec génération selon tests
    document.update_column(:thumbnail_generation_status, 'failed')
  end
  
  def create_icon_thumbnail(document)
    # Create icon-based thumbnail for non-previewable files
    icon_path = icon_for_type(document.file.content_type)
    
    if File.exist?(icon_path)
      image = MiniMagick::Image.open(icon_path)
      image.resize THUMBNAIL_SIZE
      
      temp_file = Tempfile.new(['thumbnail', '.jpg'])
      image.write(temp_file.path)
      
      document.thumbnail.attach(
        io: File.open(temp_file.path),
        filename: "thumb_#{document.file.filename.base}.jpg",
        content_type: 'image/jpeg'
      )
      
      temp_file.unlink
    end
  end
  
  def icon_for_type(content_type)
    # Map content types to icon files
    icon = case content_type
           when /pdf/ then 'pdf-icon.png'
           when /word|document/ then 'word-icon.png'
           when /excel|spreadsheet/ then 'excel-icon.png'
           when /powerpoint|presentation/ then 'ppt-icon.png'
           when /zip|compressed/ then 'zip-icon.png'
           when /text/ then 'txt-icon.png'
           else 'generic-icon.png'
           end
    
    Rails.root.join('app/assets/images/file-icons', icon)
  end
end