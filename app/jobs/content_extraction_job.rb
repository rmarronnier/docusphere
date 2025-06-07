class ContentExtractionJob < ApplicationJob
  queue_as :document_processing
  
  def perform(document)
    return unless document.file.attached?
    
    content = extract_content(document)
    
    if content.present?
      document.update!(content: content)
      document.add_metadata('word_count', content.split.size)
      document.add_metadata('extraction_method', extraction_method(document))
    end
  end
  
  private
  
  def extract_content(document)
    case
    when document.pdf?
      extract_pdf_content(document)
    when document.office_document?
      extract_office_content(document)
    when document.file.content_type == 'text/plain'
      extract_text_content(document)
    when document.file.content_type.include?('csv')
      extract_csv_content(document)
    else
      nil
    end
  end
  
  def extract_pdf_content(document)
    document.file.open do |file|
      reader = PDF::Reader.new(file)
      text = reader.pages.map(&:text).join("\n")
      text.strip
    end
  rescue PDF::Reader::EncryptedPDFError
    document.add_metadata('extraction_error', 'PDF is encrypted')
    nil
  rescue StandardError => e
    Rails.logger.error "PDF extraction failed: #{e.message}"
    nil
  end
  
  def extract_office_content(document)
    text = nil
    
    document.file.open do |file|
      # Convert to text using LibreOffice
      output_dir = Dir.mktmpdir
      
      begin
        # Use libreoffice to convert to text
        command = [
          'libreoffice',
          '--headless',
          '--convert-to', 'txt:Text',
          '--outdir', output_dir,
          file.path
        ]
        
        system(*command)
        
        # Read the converted text file
        converted_path = File.join(
          output_dir,
          File.basename(file.path, '.*') + '.txt'
        )
        
        if File.exist?(converted_path)
          text = File.read(converted_path).strip
        end
      ensure
        FileUtils.rm_rf(output_dir) if output_dir && Dir.exist?(output_dir)
      end
    end
    
    text
  rescue StandardError => e
    Rails.logger.error "Office document extraction failed: #{e.message}"
    nil
  end
  
  def extract_text_content(document)
    document.file.download.force_encoding('UTF-8')
  rescue StandardError => e
    Rails.logger.error "Text extraction failed: #{e.message}"
    nil
  end
  
  def extract_csv_content(document)
    content = document.file.download
    # Convert CSV to readable text format
    csv_data = CSV.parse(content, headers: true)
    csv_data.map { |row| row.to_h.map { |k, v| "#{k}: #{v}" }.join(", ") }.join("\n")
  rescue StandardError => e
    Rails.logger.error "CSV extraction failed: #{e.message}"
    nil
  end
  
  def extraction_method(document)
    case
    when document.pdf? then 'pdf-reader'
    when document.office_document? then 'libreoffice'
    when document.file.content_type == 'text/plain' then 'direct'
    when document.file.content_type.include?('csv') then 'csv-parser'
    else 'unknown'
    end
  end
end