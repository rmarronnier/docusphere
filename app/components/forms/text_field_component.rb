# Text input field component with type variations
class Forms::TextFieldComponent < Forms::FieldComponent
  def initialize(form:, attribute:, type: :text, placeholder: nil, autocomplete: nil, **options)
    super(form: form, attribute: attribute, **options)
    @type = type
    @placeholder = placeholder
    @autocomplete = autocomplete
  end
  
  private
  
  def render_field
    case @type
    when :email
      @form.email_field @attribute, field_options.merge(text_field_options)
    when :password
      @form.password_field @attribute, field_options.merge(text_field_options)
    when :number
      @form.number_field @attribute, field_options.merge(text_field_options)
    when :tel
      @form.telephone_field @attribute, field_options.merge(text_field_options)
    when :url
      @form.url_field @attribute, field_options.merge(text_field_options)
    when :date
      @form.date_field @attribute, field_options.merge(text_field_options)
    when :time
      @form.time_field @attribute, field_options.merge(text_field_options)
    when :datetime
      @form.datetime_field @attribute, field_options.merge(text_field_options)
    else
      @form.text_field @attribute, field_options.merge(text_field_options)
    end
  end
  
  def text_field_options
    {
      class: field_classes,
      placeholder: @placeholder,
      autocomplete: @autocomplete
    }.compact
  end
end