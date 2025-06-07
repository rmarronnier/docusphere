class ThumbnailGenerationJob < ApplicationJob
  queue_as :document_processing
  
  THUMBNAIL_SIZE = '200x200'
  
  def perform(document)
    return unless document.file.attached?
    return if document.thumbnail.attached?
    
    # Wait for preview to be generated first if it's being processed
    if should_use_preview?(document) && !document.preview.attached?
      # Re-enqueue this job to run later
      self.class.set(wait: 30.seconds).perform_later(document)
      return
    end
    
    generate_thumbnail(document)
  end
  
  private
  
  def should_use_preview?(document)
    document.pdf? || document.office_document?
  end
  
  def generate_thumbnail(document)
    source = if should_use_preview?(document) && document.preview.attached?
               document.preview
             elsif document.image?
               document.file
             else
               return create_icon_thumbnail(document)
             end
    
    source.open do |file|
      image = MiniMagick::Image.open(file.path)
      
      # Create square thumbnail
      image.combine_options do |c|
        c.resize "#{THUMBNAIL_SIZE}^"
        c.gravity 'center'
        c.extent THUMBNAIL_SIZE
      end
      
      # Optimize for web
      image.format 'jpg'
      image.quality 75
      image.strip # Remove EXIF data
      
      temp_file = Tempfile.new(['thumbnail', '.jpg'])
      image.write(temp_file.path)
      
      document.thumbnail.attach(
        io: File.open(temp_file.path),
        filename: "thumb_#{document.file.filename.base}.jpg",
        content_type: 'image/jpeg'
      )
      
      temp_file.unlink
    end
  rescue StandardError => e
    Rails.logger.error "Thumbnail generation failed: #{e.message}"
    create_icon_thumbnail(document)
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