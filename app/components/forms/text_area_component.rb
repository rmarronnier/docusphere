class Forms::TextAreaComponent < Forms::FieldComponent
  def initialize(form:, attribute:, rows: 3, placeholder: nil, resize: true, 
                 auto_resize: false, character_count: false, max_length: nil, **options)
    super(form: form, attribute: attribute, **options)
    @rows = rows
    @placeholder = placeholder
    @resize = resize
    @auto_resize = auto_resize
    @character_count = character_count
    @max_length = max_length
  end
  
  private
  
  def render_field
    content_tag :div, class: 'relative' do
      content = []
      
      # Main textarea
      content << @form.text_area(@attribute, field_options.merge(text_area_options))
      
      # Character count
      if @character_count
        content << render_character_count
      end
      
      safe_join(content)
    end
  end
  
  def render_character_count
    current_length = current_value.to_s.length
    
    content_tag :div, class: 'absolute bottom-2 right-2 text-xs text-gray-500' do
      if @max_length
        remaining = @max_length - current_length
        color_class = remaining < 10 ? 'text-red-500' : 'text-gray-500'
        content_tag :span, class: color_class do
          "#{current_length}/#{@max_length}"
        end
      else
        content_tag :span do
          "#{current_length} characters"
        end
      end
    end
  end
  
  def current_value
    @form.object.public_send(@attribute) if @form.object.respond_to?(@attribute)
  end
  
  def text_area_options
    options = {
      class: text_area_classes,
      rows: @rows,
      placeholder: @placeholder
    }.compact
    
    # Add maxlength attribute if specified
    options[:maxlength] = @max_length if @max_length
    
    # Add data attributes for JavaScript functionality
    if @auto_resize || @character_count
      options[:data] ||= {}
      options[:data][:controller] = controller_list.join(' ')
      options[:data][:action] = action_list.join(' ')
    end
    
    options
  end
  
  def controller_list
    controllers = []
    controllers << 'auto-resize' if @auto_resize
    controllers << 'character-count' if @character_count
    controllers
  end
  
  def action_list
    actions = []
    actions << 'input->auto-resize#resize' if @auto_resize
    actions << 'input->character-count#update' if @character_count
    actions
  end
  
  def text_area_classes
    classes = [field_classes]
    classes << 'resize-none' unless @resize
    classes << 'pb-8' if @character_count # Add padding for character count
    classes.join(' ')
  end
end