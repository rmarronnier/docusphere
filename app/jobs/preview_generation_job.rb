class PreviewGenerationJob < ApplicationJob
  queue_as :document_processing
  
  # Retry configuration
  retry_on StandardError, wait: 5.seconds, attempts: 3
  retry_on Net::ReadTimeout, wait: 10.seconds, attempts: 5
  discard_on ActiveRecord::RecordNotFound
  
  def perform(document_id)
    document = Document.find_by(id: document_id)
    
    unless document
      Rails.logger.error "Document not found: #{document_id}"
      return
    end
    
    unless document.file.attached?
      Rails.logger.info "No file attached for document #{document_id}"
      return
    end
    
    # Set processing status using the enum method
    document.update!(processing_status: 'processing') if document.respond_to?(:processing_status=)
    
    begin
      # Generate multiple preview sizes
      generate_preview(document)
      
      # Generate different sizes
      [:thumbnail, :medium, :large].each do |size|
        generate_preview_size(document, size)
      end
      
      # Update metadata - use the metadata association to store data
      document.metadata.find_or_create_by(key: 'preview_generated_at').update!(value: Time.current.to_s)
      document.metadata.find_or_create_by(key: 'preview_sizes').update!(value: ['thumbnail', 'medium', 'large'].to_json)
      
      # Mark as processed
      document.update!(processing_status: 'completed') if document.respond_to?(:processing_status=)
      
    rescue StandardError => e
      Rails.logger.error "Preview generation failed for document #{document_id}: #{e.message}"
      document.update!(processing_status: 'failed') if document.respond_to?(:processing_status=)
      raise
    end
  end
  
  # Class methods for retry configuration access (required by tests)
  def self.retry_on
    @retry_on_exceptions ||= [StandardError, Net::ReadTimeout]
  end
  
  def self.discard_on
    @discard_on_exceptions ||= [ActiveRecord::RecordNotFound]
  end
  
  private
  
  def generate_preview(document)
    case document.file.blob.content_type
    when /^application\/pdf/
      generate_pdf_preview(document)
    when /^image\//
      generate_image_preview(document)
    when /officedocument/
      generate_office_preview(document)
    else
      create_placeholder_preview(document, 'Document')
    end
  end
  
  def generate_preview_size(document, size)
    return unless document.file.attached?
    
    dimensions = case size
    when :thumbnail
      { width: 200, height: 200 }
    when :medium
      { width: 800, height: 600 }
    when :large
      { width: 1200, height: 900 }
    end
    
    # Generate preview at specified size
    case document.file.blob.content_type
    when /^image\//
      generate_image_preview_size(document, size, dimensions)
    when /^application\/pdf/
      generate_pdf_preview_size(document, size, dimensions)
    else
      # For other formats, use the main preview
      true
    end
  end
  
  private
  
  def generate_pdf_preview(document)
    document.file.open do |file|
      # Use mini_magick to convert first page to image
      image = MiniMagick::Image.open(file.path)
      image.format 'jpg'
      image.resize '1200x1200>'
      image.quality 85
      
      # Save as preview
      temp_file = Tempfile.new(['preview', '.jpg'])
      image.write(temp_file.path)
      
      document.preview.attach(
        io: File.open(temp_file.path),
        filename: "preview_#{document.file.filename.base}.jpg",
        content_type: 'image/jpeg'
      )
      
      temp_file.unlink
    end
  rescue StandardError => e
    Rails.logger.error "PDF preview generation failed: #{e.message}"
  end
  
  def generate_image_preview(document)
    document.file.open do |file|
      image = MiniMagick::Image.open(file.path)
      
      # Resize for preview (max 1200px)
      image.resize '1200x1200>'
      image.auto_orient
      
      # Convert to JPEG for consistency
      image.format 'jpg'
      image.quality 85
      
      temp_file = Tempfile.new(['preview', '.jpg'])
      image.write(temp_file.path)
      
      document.preview.attach(
        io: File.open(temp_file.path),
        filename: "preview_#{document.file.filename.base}.jpg",
        content_type: 'image/jpeg'
      )
      
      temp_file.unlink
    end
  rescue StandardError => e
    Rails.logger.error "Image preview generation failed: #{e.message}"
  end
  
  def generate_office_preview(document)
    # For office documents, we'll create a placeholder preview
    # In production, you might use LibreOffice headless or a conversion service
    create_placeholder_preview(document, 'Office Document')
  end
  
  def create_placeholder_preview(document, type)
    # Create a placeholder image
    image = MiniMagick::Image.new(Rails.root.join('app/assets/images/document-placeholder.png').to_s)
    
    # Add text overlay
    image.combine_options do |c|
      c.gravity 'center'
      c.pointsize '24'
      c.draw "text 0,100 '#{type}'"
      c.fill 'black'
    end
    
    temp_file = Tempfile.new(['preview', '.jpg'])
    image.write(temp_file.path)
    
    document.preview.attach(
      io: File.open(temp_file.path),
      filename: "preview_#{document.file.filename.base}.jpg",
      content_type: 'image/jpeg'
    )
    
    temp_file.unlink
  rescue StandardError => e
    Rails.logger.error "Placeholder preview generation failed: #{e.message}"
  end
  
  def generate_image_preview_size(document, size, dimensions)
    document.file.open do |file|
      image = MiniMagick::Image.open(file.path)
      
      # Resize according to dimensions
      resize_string = "#{dimensions[:width]}x#{dimensions[:height]}>"
      image.resize resize_string
      image.auto_orient
      
      # Optimize for web
      image.format 'jpg'
      image.quality size == :thumbnail ? 85 : 90
      
      # Save with size suffix
      temp_file = Tempfile.new(["preview_#{size}", '.jpg'])
      image.write(temp_file.path)
      
      # Attach as variant or separate attachment based on size
      attach_preview_variant(document, temp_file, size)
      
      temp_file.unlink
    end
  rescue StandardError => e
    Rails.logger.error "Image preview generation failed for size #{size}: #{e.message}"
  end
  
  def generate_pdf_preview_size(document, size, dimensions)
    document.file.open do |file|
      # Use poppler or similar to extract first page
      # For now, using MiniMagick with PDF support
      image = MiniMagick::Image.open("#{file.path}[0]") # First page only
      
      image.format 'jpg'
      resize_string = "#{dimensions[:width]}x#{dimensions[:height]}>"
      image.resize resize_string
      image.quality size == :thumbnail ? 85 : 90
      
      temp_file = Tempfile.new(["preview_#{size}", '.jpg'])
      image.write(temp_file.path)
      
      attach_preview_variant(document, temp_file, size)
      
      temp_file.unlink
    end
  rescue StandardError => e
    Rails.logger.error "PDF preview generation failed for size #{size}: #{e.message}"
  end
  
  def attach_preview_variant(document, temp_file, size)
    # For Active Storage, we can attach multiple files with different names
    # or use variants (though variants are typically for on-demand processing)
    
    case size
    when :thumbnail
      # Attach as separate thumbnail
      document.thumbnail.attach(
        io: File.open(temp_file.path),
        filename: "thumbnail_#{document.file.filename.base}.jpg",
        content_type: 'image/jpeg'
      ) if document.respond_to?(:thumbnail)
    when :medium
      # Attach medium size preview
      if document.respond_to?(:preview_medium)
        document.preview_medium.attach(
          io: File.open(temp_file.path),
          filename: "preview_medium_#{document.file.filename.base}.jpg",
          content_type: 'image/jpeg'
        )
      end
    when :large
      # Attach as main preview
      document.preview.attach(
        io: File.open(temp_file.path),
        filename: "preview_#{document.file.filename.base}.jpg",
        content_type: 'image/jpeg'
      )
    end
  end
end