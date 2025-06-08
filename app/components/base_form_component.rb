# Abstract base component for form elements with consistent styling
class BaseFormComponent < ApplicationComponent
  # Base component for form fields
  class FieldComponent < ApplicationComponent
    def initialize(form:, attribute:, label: nil, hint: nil, required: false, wrapper_class: nil)
      @form = form
      @attribute = attribute
      @label = label
      @hint = hint
      @required = required
      @wrapper_class = wrapper_class || 'mb-4'
    end
    
    def call
      content_tag :div, class: @wrapper_class do
        concat render_label if should_render_label?
        concat render_field
        concat render_hint if @hint
        concat render_errors if has_errors?
      end
    end
    
    protected
    
    def render_label
      label_text = @label || @attribute.to_s.humanize
      label_text += ' *' if @required
      
      @form.label @attribute, label_text, class: label_classes
    end
    
    def render_field
      raise NotImplementedError, "Subclasses must implement render_field"
    end
    
    def render_hint
      content_tag :p, @hint, class: 'mt-1 text-sm text-gray-500'
    end
    
    def render_errors
      content_tag :p, class: 'mt-1 text-sm text-red-600' do
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
      base = 'block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm'
      base += ' border-red-300 text-red-900 placeholder-red-300 focus:border-red-500 focus:ring-red-500' if has_errors?
      base
    end
  end
  
  # Text field component
  class TextFieldComponent < FieldComponent
    def initialize(form:, attribute:, type: :text, placeholder: nil, **options)
      super(form: form, attribute: attribute, **options)
      @type = type
      @placeholder = placeholder
    end
    
    protected
    
    def render_field
      case @type
      when :email
        @form.email_field @attribute, class: field_classes, placeholder: @placeholder
      when :password
        @form.password_field @attribute, class: field_classes, placeholder: @placeholder
      when :number
        @form.number_field @attribute, class: field_classes, placeholder: @placeholder
      when :tel
        @form.telephone_field @attribute, class: field_classes, placeholder: @placeholder
      when :url
        @form.url_field @attribute, class: field_classes, placeholder: @placeholder
      else
        @form.text_field @attribute, class: field_classes, placeholder: @placeholder
      end
    end
  end
  
  # Textarea component
  class TextAreaComponent < FieldComponent
    def initialize(form:, attribute:, rows: 3, placeholder: nil, **options)
      super(form: form, attribute: attribute, **options)
      @rows = rows
      @placeholder = placeholder
    end
    
    protected
    
    def render_field
      @form.text_area @attribute, 
                      class: field_classes, 
                      rows: @rows,
                      placeholder: @placeholder
    end
  end
  
  # Select component
  class SelectComponent < FieldComponent
    def initialize(form:, attribute:, options:, include_blank: false, prompt: nil, **field_options)
      super(form: form, attribute: attribute, **field_options)
      @options = options
      @include_blank = include_blank
      @prompt = prompt
    end
    
    protected
    
    def render_field
      @form.select @attribute,
                   @options,
                   { include_blank: @include_blank, prompt: @prompt },
                   class: field_classes
    end
  end
  
  # Checkbox component
  class CheckboxComponent < FieldComponent
    def initialize(form:, attribute:, label_text: nil, **options)
      super(form: form, attribute: attribute, **options)
      @label_text = label_text || @label || @attribute.to_s.humanize
    end
    
    protected
    
    def should_render_label?
      false # We render a custom label
    end
    
    def render_field
      content_tag :div, class: 'flex items-start' do
        concat content_tag(:div, class: 'flex items-center h-5') do
          @form.check_box @attribute,
                          class: 'h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-500'
        end
        concat content_tag(:div, class: 'ml-3 text-sm') do
          @form.label @attribute, @label_text, class: 'font-medium text-gray-700'
        end
      end
    end
  end
  
  # Radio button group component
  class RadioGroupComponent < FieldComponent
    def initialize(form:, attribute:, options:, **field_options)
      super(form: form, attribute: attribute, **field_options)
      @options = options
    end
    
    protected
    
    def render_field
      content_tag :div, class: 'space-y-2' do
        @options.map do |option|
          value = option.is_a?(Array) ? option.last : option
          label = option.is_a?(Array) ? option.first : option.to_s.humanize
          
          content_tag :div, class: 'flex items-center' do
            concat @form.radio_button(@attribute, value, class: 'h-4 w-4 border-gray-300 text-indigo-600 focus:ring-indigo-500')
            concat content_tag(:label, label, for: "#{@form.object_name}_#{@attribute}_#{value}", class: 'ml-3 text-sm font-medium text-gray-700')
          end
        end.join.html_safe
      end
    end
  end
end