class PreviewGenerationJob < ApplicationJob
  queue_as :document_processing
  
  def perform(document)
    return unless document.file.attached?
    return if document.preview.attached?
    
    case
    when document.pdf?
      generate_pdf_preview(document)
    when document.image?
      generate_image_preview(document)
    when document.office_document?
      generate_office_preview(document)
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
end