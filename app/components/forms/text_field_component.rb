# Text input field component with type variations
class Forms::TextFieldComponent < Forms::FieldComponent
  def initialize(form:, attribute:, type: :text, placeholder: nil, autocomplete: nil, **options)
    super(form: form, attribute: attribute, **options)
    @type = type
    @placeholder = placeholder
    @autocomplete = autocomplete
  end
  
  private
  
  def text_field_options
    {
      class: field_classes,
      placeholder: @placeholder,
      autocomplete: @autocomplete,
      required: @required
    }.compact
  end
end