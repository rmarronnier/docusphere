class DocumentProcessingService
  def initialize(document)
    @document = document
  end

  def process!
    return false unless @document.file.attached?

    begin
      @document.update(processing_status: 'processing')
      
      extract_text
      extract_metadata  
      generate_thumbnail
      run_virus_scan
      apply_auto_tagging
      
      @document.update(processing_status: 'completed')
      true
    rescue => e
      Rails.logger.error "Document processing failed: #{e.message}"
      @document.update(processing_status: 'failed', processing_error: e.message)
      false
    end
  end

  private

  attr_reader :document

  def extract_text
    case document.file_content_type
    when 'application/pdf'
      document.extracted_text = extract_pdf_text(document.file.download)
    when /^image\//
      document.extracted_text = extract_ocr_text(document.file.download)
    when 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
      document.extracted_text = extract_docx_text(document.file.download)
    else
      document.extracted_text = ''
    end
    document.save
  end

  def extract_metadata
    if document.file.attached?
      document.file_size = document.file.byte_size
      document.content_hash = calculate_content_hash(document.file.download)
    end
    document.save
  end

  def generate_thumbnail
    case document.file_content_type
    when /^image\//
      generate_image_thumbnail
    when 'application/pdf'
      generate_pdf_thumbnail
    end
  end

  def run_virus_scan
    result = scan_with_clamav(document.file.download)
    if result[:clean]
      document.virus_scan_status = 'clean'
      document.virus_scan_result = 'No threats detected'
    else
      document.virus_scan_status = 'infected'
      document.virus_scan_result = result[:signature] || 'Threat detected'
      document.quarantined = true
    end
    document.save
  end

  def apply_auto_tagging
    return unless document.extracted_text.present?

    suggested_tags = suggest_tags_from_content(document.extracted_text)
    suggested_tags.each do |tag_name|
      # Tags require organization - get it from document's space
      organization = document.space.organization
      tag = Tag.find_or_create_by(name: tag_name.downcase.strip, organization: organization)
      document.tags << tag unless document.tags.include?(tag)
    end
  end

  private

  # Helper methods that would integrate with external services in production
  def extract_pdf_text(content)
    "Mock PDF text extraction for content of #{content.length} bytes"
  end

  def extract_ocr_text(content)
    "Mock OCR text extraction for image of #{content.length} bytes"
  end

  def extract_docx_text(content)
    "Mock DOCX text extraction for content of #{content.length} bytes"
  end

  def calculate_content_hash(content)
    Digest::SHA256.hexdigest(content)
  end

  def generate_image_thumbnail
    # Mock thumbnail generation
    Rails.logger.info "Generating image thumbnail for document #{document.id}"
  end

  def generate_pdf_thumbnail
    # Mock thumbnail generation  
    Rails.logger.info "Generating PDF thumbnail for document #{document.id}"
  end

  def scan_with_clamav(content)
    # Mock virus scan - always return clean for testing
    { clean: true, signature: nil }
  end

  def suggest_tags_from_content(content)
    # Simple keyword-based tagging
    keywords = %w[contract invoice legal technical administrative financial construction architecture plan permit budget]
    content_words = content.downcase.split(/\W+/)
    
    keywords.select do |keyword|
      content_words.any? { |word| word.include?(keyword) }
    end
  end

  def needs_ocr?
    document.file_content_type&.start_with?('image/')
  end
end