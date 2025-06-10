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
end