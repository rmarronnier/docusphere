class MetadataExtractionJob < ApplicationJob
  queue_as :document_processing
  
  def perform(document)
    return unless document.file.attached? && document.content.present?
    
    # Extract file metadata
    extract_file_metadata(document)
    
    # Extract content-based metadata
    extract_content_metadata(document)
    
    # Extract dates from content
    extract_dates(document)
    
    # Extract amounts/money
    extract_amounts(document)
    
    # Extract reference numbers
    extract_references(document)
    
    # Extract emails and phone numbers
    extract_contact_info(document)
  end
  
  private
  
  def extract_file_metadata(document)
    blob = document.file.blob
    
    metadata = {
      file_size: blob.byte_size,
      file_name: blob.filename.to_s,
      content_type: blob.content_type,
      created_at: blob.created_at
    }
    
    # Add image-specific metadata
    if document.image? && blob.metadata.present?
      metadata.merge!(
        width: blob.metadata['width'],
        height: blob.metadata['height'],
        analyzed_at: blob.metadata['analyzed'] ? Time.current : nil
      )
    end
    
    document.store_document_properties(metadata.compact)
  end
  
  def extract_content_metadata(document)
    content = document.content
    return if content.blank?
    
    # Basic statistics
    stats = {
      character_count: content.length,
      line_count: content.lines.count,
      paragraph_count: content.split(/\n\s*\n/).count
    }
    
    document.store_document_properties(stats)
  end
  
  def extract_dates(document)
    content = document.content
    return if content.blank?
    
    # Find dates in various formats
    date_patterns = [
      /\d{1,2}\/\d{1,2}\/\d{2,4}/,          # DD/MM/YYYY or MM/DD/YYYY
      /\d{1,2}-\d{1,2}-\d{2,4}/,            # DD-MM-YYYY
      /\d{4}-\d{1,2}-\d{1,2}/,              # YYYY-MM-DD
      /\d{1,2}\s+(janvier|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre)\s+\d{4}/i,
      /\d{1,2}\s+(january|february|march|april|may|june|july|august|september|october|november|december)\s+\d{4}/i
    ]
    
    found_dates = []
    date_patterns.each do |pattern|
      content.scan(pattern).each do |match|
        date_str = match.is_a?(Array) ? match.join(' ') : match
        begin
          parsed_date = Chronic.parse(date_str)
          found_dates << parsed_date if parsed_date
        rescue
          # Ignore parsing errors
        end
      end
    end
    
    # Store the most relevant dates
    if found_dates.any?
      document.add_metadata('earliest_date', found_dates.min.to_date.to_s)
      document.add_metadata('latest_date', found_dates.max.to_date.to_s)
      
      # If only one date, it might be the document date
      if found_dates.uniq.size == 1
        document.add_metadata('document_date', found_dates.first.to_date.to_s)
      end
    end
  end
  
  def extract_amounts(document)
    content = document.content
    return if content.blank?
    
    # Find monetary amounts
    amount_patterns = [
      /(?:€|EUR)\s*(\d+(?:[.,]\d{3})*(?:[.,]\d{2})?)/,           # €1,234.56 or EUR 1.234,56
      /(\d+(?:[.,]\d{3})*(?:[.,]\d{2})?)\s*(?:€|EUR)/,           # 1,234.56€ or 1.234,56 EUR
      /(\d+(?:[.,]\d{3})*(?:[.,]\d{2})?)\s*(?:euros?|dollars?)/i # 1,234.56 euros
    ]
    
    amounts = []
    amount_patterns.each do |pattern|
      content.scan(pattern).each do |match|
        amount_str = match.first.gsub(/[^\d,.]/, '').gsub(',', '.')
        begin
          amount = Monetize.parse(amount_str)
          amounts << amount if amount && amount.cents > 0
        rescue
          # Ignore parsing errors
        end
      end
    end
    
    if amounts.any?
      # Store total and range
      document.add_metadata('total_amount', amounts.sum.to_s)
      document.add_metadata('min_amount', amounts.min.to_s)
      document.add_metadata('max_amount', amounts.max.to_s)
      document.add_metadata('amount_count', amounts.size.to_s)
    end
  end
  
  def extract_references(document)
    content = document.content
    return if content.blank?
    
    # Common reference patterns
    reference_patterns = {
      invoice_number: /(?:facture|invoice)\s*(?:n°|#|:)?\s*([A-Z0-9\-\/]+)/i,
      contract_number: /(?:contrat|contract)\s*(?:n°|#|:)?\s*([A-Z0-9\-\/]+)/i,
      order_number: /(?:commande|order)\s*(?:n°|#|:)?\s*([A-Z0-9\-\/]+)/i,
      reference: /(?:réf(?:érence)?|ref(?:erence)?)\s*(?::|n°)?\s*([A-Z0-9\-\/]+)/i,
      project_code: /(?:projet|project)\s*(?::|n°)?\s*([A-Z0-9\-\/]+)/i
    }
    
    reference_patterns.each do |type, pattern|
      matches = content.scan(pattern).flatten.uniq
      if matches.any?
        document.add_metadata("#{type}", matches.first)
        document.add_metadata("all_#{type}s", matches.join(', ')) if matches.size > 1
      end
    end
  end
  
  def extract_contact_info(document)
    content = document.content
    return if content.blank?
    
    # Email pattern
    email_pattern = /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/
    emails = content.scan(email_pattern).uniq
    
    if emails.any?
      document.add_metadata('emails', emails.join(', '))
      document.add_metadata('primary_email', emails.first)
    end
    
    # Phone patterns (French and international)
    phone_patterns = [
      /(?:\+33|0)\s?[1-9](?:\s?\d{2}){4}/,                    # French phones
      /\+\d{1,3}\s?\d{4,14}/,                                 # International
      /\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}/                   # US format
    ]
    
    phones = []
    phone_patterns.each do |pattern|
      phones.concat(content.scan(pattern))
    end
    
    if phones.any?
      document.add_metadata('phone_numbers', phones.uniq.join(', '))
    end
  end
end