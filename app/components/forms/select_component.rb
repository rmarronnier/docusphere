class Forms::SelectComponent < Forms::FieldComponent
  def initialize(form:, attribute:, options:, include_blank: false, prompt: nil, multiple: false, searchable: false, **field_options)
    super(form: form, attribute: attribute, **field_options)
    @select_options = options
    @include_blank = include_blank
    @prompt = prompt
    @multiple = multiple
    @searchable = searchable
  end
  
  private
  
  def render_field
    if @searchable
      render_searchable_select
    else
      @form.select @attribute, formatted_options, select_html_options, field_options.merge(select_field_options)
    end
  end
  
  def render_searchable_select
    select_id = field_id
    search_id = "#{select_id}_search"
    
    content_tag :div, class: 'relative' do
      content = []
      
      # Hidden select field for form submission
      content << @form.select(@attribute, formatted_options, select_html_options, 
                             field_options.merge(select_field_options).merge(class: 'hidden', 
                             data: { searchable_target: 'select' }))
      
      # Search input
      content << content_tag(:input, nil,
        type: 'text',
        id: search_id,
        class: "#{field_classes} pr-10",
        placeholder: search_placeholder,
        autocomplete: 'off',
        data: { 
          searchable_target: 'input',
          action: 'input->searchable#filter focus->searchable#open blur->searchable#close'
        }
      )
      
      # Dropdown icon
      content << content_tag(:div, class: 'absolute inset-y-0 right-0 flex items-center pr-2 pointer-events-none') do
        content_tag :svg, class: 'h-5 w-5 text-gray-400', fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' do
          content_tag :path, nil, 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M19 9l-7 7-7-7'
        end
      end
      
      # Options dropdown
      content << content_tag(:div, 
        class: 'absolute z-10 mt-1 w-full bg-white shadow-lg max-h-60 rounded-md py-1 text-base ring-1 ring-black ring-opacity-5 overflow-auto focus:outline-none sm:text-sm hidden',
        data: { searchable_target: 'dropdown' }
      ) do
        render_searchable_options
      end
      
      safe_join(content)
    end
  end
  
  def render_searchable_options
    options_html = []
    
    formatted_options.each do |option|
      text, value = option.is_a?(Array) ? option : [option, option]
      
      options_html << content_tag(:div,
        text,
        class: 'cursor-pointer select-none relative py-2 pl-3 pr-9 hover:bg-indigo-600 hover:text-white',
        data: { 
          searchable_target: 'option',
          value: value,
          text: text.to_s.downcase,
          action: 'click->searchable#select'
        }
      )
    end
    
    safe_join(options_html)
  end
  
  def formatted_options
    return @select_options if @select_options.is_a?(String) # options_for_select already called
    @select_options
  end
  
  def select_html_options
    { include_blank: @include_blank, prompt: @prompt }
  end
  
  def select_field_options
    options = { multiple: @multiple }.compact
    options[:data] ||= {}
    options[:data][:controller] = 'searchable' if @searchable
    options
  end
  
  def selected_value
    @form.object.public_send(@attribute) if @form.object.respond_to?(@attribute)
  end
  
  def search_placeholder
    if @multiple
      'Select multiple options...'
    else
      @prompt || 'Select an option...'
    end
  end
end