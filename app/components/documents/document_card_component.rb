class Documents::DocumentCardComponent < ApplicationComponent
  def initialize(document:)
    @document = document
  end

  private

  attr_reader :document

  def document_icon
    case document.document_type
    when 'pdf'
      'document-text'
    when 'word'
      'document'
    when 'excel'
      'table'
    when 'powerpoint'
      'presentation-chart-bar'
    when 'image'
      'photograph'
    when 'audio'
      'volume-up'
    when 'video'
      'video-camera'
    when 'mail'
      'mail'
    when 'zip'
      'archive'
    else
      'document'
    end
  end

  def status_badge_classes
    base = "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
    case document.status
    when 'draft'
      "#{base} bg-gray-100 text-gray-800"
    when 'published'
      "#{base} bg-green-100 text-green-800"
    when 'locked'
      "#{base} bg-yellow-100 text-yellow-800"
    when 'archived'
      "#{base} bg-blue-100 text-blue-800"
    else
      "#{base} bg-gray-100 text-gray-800"
    end
  end

  def formatted_date
    l(document.created_at, format: :short) if document.created_at
  end

  def file_size
    return unless document.file.attached?
    
    size = document.file.blob.byte_size
    if size < 1024
      "#{size} B"
    elsif size < 1048576
      "#{(size / 1024.0).round(1)} KB"
    else
      "#{(size / 1048576.0).round(1)} MB"
    end
  end
end