class Forms::CheckboxComponent < Forms::FieldComponent
  def initialize(form:, attribute:, label_text: nil, checked: nil, **options)
    super(form: form, attribute: attribute, **options)
    @label_text = label_text || @label || @attribute.to_s.humanize
    @checked = checked
  end
  
  protected
  
  def should_render_label?
    false # We render a custom label with the checkbox
  end
  
  private
  
  def checkbox_classes
    base = 'h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-500'
    base += ' border-red-300' if has_errors?
    base
  end
end