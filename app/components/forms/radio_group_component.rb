class Forms::RadioGroupComponent < Forms::FieldComponent
  def initialize(form:, attribute:, options:, layout: :vertical, **field_options)
    super(form: form, attribute: attribute, **field_options)
    @radio_options = options
    @layout = layout
  end
  
  private
  
  def formatted_options
    @radio_options.map do |option|
      if option.is_a?(Array)
        option
      else
        [option.to_s.humanize, option]
      end
    end
  end
  
  def radio_classes
    base = 'h-4 w-4 border-gray-300 text-indigo-600 focus:ring-indigo-500'
    base += ' border-red-300' if has_errors?
    base
  end
  
  def label_text
    text = @label || @attribute.to_s.humanize
    @required ? "#{text} *" : text
  end
end