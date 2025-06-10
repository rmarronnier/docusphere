# Base component for all form fields with consistent styling and error handling
class Forms::FieldComponent < ApplicationComponent
  def initialize(form:, attribute:, label: nil, hint: nil, required: false, wrapper_class: nil, **options)
    @form = form
    @attribute = attribute.to_sym
    @label = label
    @hint = hint
    @required = required
    @wrapper_class = wrapper_class || 'mb-4'
    @options = options
  end

  protected

  attr_reader :form, :attribute, :label, :hint, :required, :wrapper_class, :options

  def render_label
    label_text = @label || @attribute.to_s.humanize
    label_text += ' *' if @required
    
    @form.label @attribute, label_text, class: label_classes
  end
  
  def render_field
    raise NotImplementedError, "Subclasses must implement render_field"
  end
  
  def render_hint
    content_tag :p, @hint, class: 'mt-1 text-sm text-gray-500', id: hint_id
  end
  
  def render_errors
    content_tag :p, class: 'mt-1 text-sm text-red-600', id: error_id do
      @form.object.errors[@attribute].join(', ')
    end
  end
  
  def should_render_label?
    true
  end
  
  def has_errors?
    @form.object.errors[@attribute].present?
  end

  def label_classes
    'block text-sm font-medium text-gray-700 mb-1'
  end
  
  def field_classes
    base = 'block w-full rounded-md shadow-sm sm:text-sm'
    base += ' border-gray-300 focus:border-indigo-500 focus:ring-indigo-500'
    base += ' border-red-300 text-red-900 placeholder-red-300 focus:border-red-500 focus:ring-red-500' if has_errors?
    base += " #{@options[:class]}" if @options[:class]
    base
  end

  def field_id
    "#{@form.object_name}_#{@attribute}".gsub(/\[|\]/, '_').gsub(/__+/, '_').chomp('_')
  end
  
  def hint_id
    "#{field_id}_hint"
  end
  
  def error_id
    "#{field_id}_error"
  end
  
  def aria_describedby
    ids = []
    ids << hint_id if @hint.present?
    ids << error_id if has_errors?
    ids.join(' ') if ids.any?
  end
  
  def field_options
    opts = @options.dup
    opts[:id] ||= field_id
    opts[:required] = true if @required
    opts[:aria] ||= {}
    opts[:aria][:describedby] = aria_describedby if aria_describedby
    opts[:aria][:invalid] = true if has_errors?
    opts
  end

end