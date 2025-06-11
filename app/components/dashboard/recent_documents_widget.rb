class Dashboard::RecentDocumentsWidget < ApplicationComponent
  attr_reader :widget_data, :user
  
  def initialize(widget_data:, user:)
    @widget_data = widget_data
    @user = user
  end
  
  private
  
  def documents
    @documents ||= widget_data[:data][:documents] || []
  end
  
  def document_limit
    widget_data.dig(:config, :limit) || 5
  end
  
  def total_count
    widget_data.dig(:data, :total_count) || documents.size
  end
  
  def loading?
    widget_data[:loading] == true
  end
  
  def has_more_documents?
    total_count > document_limit
  end
  
  def formatted_size(size_in_bytes)
    return '0 B' if size_in_bytes.nil? || size_in_bytes.zero?
    
    units = ['B', 'KB', 'MB', 'GB', 'TB']
    index = (Math.log(size_in_bytes) / Math.log(1024)).floor
    size = size_in_bytes.to_f / (1024 ** index)
    
    # Format with no decimals if it's a whole number
    if size == size.round
      "#{size.round} #{units[index]}"
    elsif size >= 10
      "#{size.round} #{units[index]}"
    else
      "#{size.round(1)} #{units[index]}"
    end
  end
  
  def file_extension(filename)
    return 'unknown' if filename.blank?
    
    File.extname(filename).delete('.').downcase
  end
  
  def file_icon_class(extension)
    case extension
    when 'pdf'
      'text-red-600'
    when 'doc', 'docx'
      'text-blue-600'
    when 'xls', 'xlsx'
      'text-green-600'
    when 'ppt', 'pptx'
      'text-orange-600'
    when 'jpg', 'jpeg', 'png', 'gif'
      'text-purple-600'
    when 'zip', 'rar', '7z'
      'text-gray-600'
    else
      'text-gray-500'
    end
  end
  
  def relative_time(timestamp)
    return '' unless timestamp
    
    I18n.l(timestamp, format: :relative)
  rescue
    # Fallback to distance_of_time_in_words
    time_ago_in_words(timestamp)
  end
  
  def time_ago_in_words(timestamp)
    return '' unless timestamp
    
    seconds = Time.current - timestamp
    
    case seconds
    when 0..59
      'à l\'instant'
    when 60..3599
      minutes = (seconds / 60).round
      "il y a #{minutes} minute#{'s' if minutes > 1}"
    when 3600..86399
      hours = (seconds / 3600).round
      "il y a environ #{hours == 1 ? 'une' : hours} heure#{'s' if hours > 1}"
    when 86400..604799
      days = (seconds / 86400).round
      "il y a #{days} jour#{'s' if days > 1}"
    else
      timestamp.strftime('%d/%m/%Y')
    end
  end
  
  def document_path(document)
    helpers.ged_document_path(document)
  end
  
  def my_documents_path
    helpers.my_documents_path
  end
  
  def upload_path
    '/ged/upload'
  end
end