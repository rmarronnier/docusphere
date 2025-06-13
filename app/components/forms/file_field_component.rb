# File upload field component with drag and drop, preview, and progress features
class Forms::FileFieldComponent < Forms::FieldComponent
  def initialize(form:, attribute:, accept: nil, multiple: false, 
                 drag_drop: true, preview: true, progress: true, 
                 max_file_size: nil, max_files: nil, **options)
    super(form: form, attribute: attribute, **options)
    @accept = accept
    @multiple = multiple
    @drag_drop = drag_drop
    @preview = preview
    @progress = progress
    @max_file_size = max_file_size
    @max_files = max_files
  end
  
  private
  
  def render_drag_drop_zone
    drag_zone = content_tag :div, 
      class: drag_zone_classes,
      data: drag_zone_data do
      
      content_tag :div, class: 'text-center' do
        content = []
        
        # Upload icon
        content << content_tag(:svg, class: 'mx-auto h-12 w-12 text-gray-400', 
                              stroke: 'currentColor', fill: 'none', viewBox: '0 0 48 48') do
          content_tag :path, nil, d: 'M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02', 'stroke-width': '2', 'stroke-linecap': 'round', 'stroke-linejoin': 'round'
        end
        
        # Upload text
        content << content_tag(:div, class: 'mt-4') do
          text_content = []
          text_content << content_tag(:p, class: 'text-sm text-gray-600') do
            safe_join([
              content_tag(:span, 'Click to upload', class: 'font-medium text-indigo-600 hover:text-indigo-500'),
              ' or drag and drop'
            ])
          end
          
          if @accept
            text_content << content_tag(:p, class: 'text-xs text-gray-500') do
              "Accepted formats: #{accepted_formats_text}"
            end
          end
          
          if @max_file_size
            text_content << content_tag(:p, class: 'text-xs text-gray-500') do
              "Maximum file size: #{humanize_file_size(@max_file_size)}"
            end
          end
          
          safe_join(text_content)
        end
        
        safe_join(content)
      end
    end
    
    safe_join([drag_zone, render_hidden_file_input])
  end
  
  def render_standard_file_input
    @form.file_field @attribute, file_input_options.merge(field_options)
  end
  
  def render_hidden_file_input
    options = file_input_options.merge(field_options)
    options[:class] = 'sr-only'
    options[:data] = options[:data].merge(file_upload_target: 'input')
    @form.file_field @attribute, options
  end
  
  def render_file_list
    content_tag :div, 
      class: 'mt-4 space-y-2',
      data: { file_upload_target: 'fileList' } do
      content_tag :div, class: 'text-sm text-gray-500' do
        'Selected files will appear here'
      end
    end
  end
  
  def render_progress_area
    content_tag :div, 
      class: 'mt-4 hidden',
      data: { file_upload_target: 'progressArea' } do
      
      progress_bar = content_tag :div, class: 'bg-gray-200 rounded-full h-2' do
        content_tag :div, '',
          class: 'bg-indigo-600 h-2 rounded-full transition-all duration-300',
          style: 'width: 0%',
          data: { file_upload_target: 'progressBar' }
      end
      
      progress_text = content_tag(:p, 
        class: 'text-sm text-gray-600 mt-2',
        data: { file_upload_target: 'progressText' }
      ) do
        'Uploading...'
      end
      
      safe_join([progress_bar, progress_text])
    end
  end
  
  def render_error_area
    content_tag :div, 
      class: 'mt-4 hidden',
      data: { file_upload_target: 'errorArea' } do
      
      content_tag :div, class: 'rounded-md bg-red-50 p-4' do
        content_tag :div, class: 'flex' do
          icon_section = content_tag(:div, class: 'flex-shrink-0') do
            content_tag :svg, class: 'h-5 w-5 text-red-400', fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' do
              content_tag :path, nil, 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z'
            end
          end
          
          error_list_section = content_tag(:div, class: 'ml-3') do
            content_tag :ul, '', 
              class: 'list-disc list-inside text-sm text-red-700',
              data: { file_upload_target: 'errorList' }
          end
          
          safe_join([icon_section, error_list_section])
        end
      end
    end
  end
  
  def drag_zone_classes
    base_classes = [
      'relative border-2 border-gray-300 border-dashed rounded-lg p-6',
      'hover:border-gray-400 focus:outline-none focus:ring-2',
      'focus:ring-offset-2 focus:ring-indigo-500 cursor-pointer',
      'transition-colors duration-200'
    ]
    
    base_classes << 'border-red-300' if has_errors?
    base_classes.join(' ')
  end
  
  def drag_zone_data
    {
      file_upload_target: 'dropZone',
      action: [
        'click->file-upload#openFileDialog',
        'dragover->file-upload#handleDragOver',
        'dragleave->file-upload#handleDragLeave',
        'drop->file-upload#handleDrop'
      ].join(' '),
      controller: 'file-upload',
      max_file_size: @max_file_size,
      max_files: @max_files,
      accepted_types: @accept
    }.compact
  end
  
  def file_input_options
    {
      accept: @accept,
      multiple: @multiple,
      data: {
        action: 'change->file-upload#handleFileSelect'
      }
    }.compact
  end
  
  def accepted_formats_text
    return 'All files' unless @accept
    
    formats = @accept.split(',').map(&:strip)
    has_mime_types = formats.any? { |f| f.include?('/') && !f.start_with?('.') && !f.end_with?('/*') }
    
    formats.map do |format|
      if format.include?('/')
        # MIME type like 'image/*' or 'application/pdf'
        if format.end_with?('/*')
          # For wildcards, show with '/' only if there are specific MIME types in the list
          base = format.split('/').first.upcase
          has_mime_types ? base + '/' : base
        else
          format.upcase
        end
      else
        # Extension like '.pdf'
        format.gsub('.', '').upcase
      end
    end.join(', ')
  end
  
  def humanize_file_size(bytes)
    return '0 B' if bytes == 0
    
    units = ['B', 'KB', 'MB', 'GB']
    exp = (Math.log(bytes) / Math.log(1024)).floor
    exp = [exp, units.length - 1].min
    
    size = (bytes.to_f / (1024 ** exp)).round(1)
    "#{size} #{units[exp]}"
  end
end