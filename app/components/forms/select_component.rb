class Forms::SelectComponent < Forms::FieldComponent
  def initialize(form:, attribute:, options:, include_blank: false, prompt: nil, multiple: false, **field_options)
    super(form: form, attribute: attribute, **field_options)
    @select_options = options
    @include_blank = include_blank
    @prompt = prompt
    @multiple = multiple
  end
  
  private
  
  def formatted_options
    return @select_options if @select_options.is_a?(String) # options_for_select already called
    @select_options
  end
  
  def select_html_options
    { include_blank: @include_blank, prompt: @prompt }
  end
  
  def select_options
    { class: field_classes, multiple: @multiple, required: @required }.compact
  end
  
  def selected_value
    @form.object.public_send(@attribute) if @form.object.respond_to?(@attribute)
  end
end