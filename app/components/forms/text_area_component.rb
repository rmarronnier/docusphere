class Forms::TextAreaComponent < Forms::FieldComponent
  def initialize(form:, attribute:, rows: 3, placeholder: nil, resize: true, **options)
    super(form: form, attribute: attribute, **options)
    @rows = rows
    @placeholder = placeholder
    @resize = resize
  end
  
  private
  
  def text_area_options
    {
      class: text_area_classes,
      rows: @rows,
      placeholder: @placeholder,
      required: @required
    }.compact
  end
  
  def text_area_classes
    classes = [field_classes]
    classes << 'resize-none' unless @resize
    classes.join(' ')
  end
end