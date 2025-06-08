class Forms::FieldComponent < ApplicationComponent
  def initialize(form:, field:, type: :text, label: nil, required: false, help: nil, **options)
    @form = form
    @field = field.to_sym
    @type = type.to_sym
    @label = label
    @required = required
    @help = help
    @options = options
  end

  private

  attr_reader :form, :field, :type, :label, :required, :help, :options

  def field_id
    @field_id ||= "#{form.object_name}_#{field}"
  end

  def label_text
    @label_text ||= label.presence || field.to_s.humanize
  end

  def label_classes
    "block text-sm font-medium text-gray-700"
  end

  def input_classes
    base_classes = "mt-1 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
    focus_classes = "focus:ring-indigo-500 focus:border-indigo-500"
    error_classes = has_errors? ? "border-red-300 text-red-900 placeholder-red-300 focus:ring-red-500 focus:border-red-500" : ""
    
    merged_classes = [base_classes, focus_classes, error_classes].reject(&:blank?).join(" ")
    
    # Merge avec les classes personnalisées si fournies
    if options[:class]
      "#{merged_classes} #{options[:class]}"
    else
      merged_classes
    end
  end

  def field_options
    opts = options.dup
    opts[:class] = input_classes
    opts[:id] = field_id
    opts[:required] = true if required
    opts[:aria] ||= {}
    opts[:aria][:describedby] = help_id if help.present?
    opts[:aria][:invalid] = true if has_errors?
    opts
  end

  def help_id
    "#{field_id}_help"
  end

  def has_errors?
    form.object.errors[field].any?
  end

  def error_messages
    form.object.errors[field]
  end

  def render_input
    case type
    when :text, :email, :password, :tel, :url
      form.text_field(field, field_options.merge(type: type))
    when :textarea
      form.text_area(field, field_options.merge(rows: options[:rows] || 3))
    when :select
      form.select(field, options[:choices] || [], { prompt: options[:prompt] }, field_options)
    when :file
      form.file_field(field, field_options)
    when :hidden
      form.hidden_field(field, field_options)
    when :number
      form.number_field(field, field_options)
    when :date
      form.date_field(field, field_options)
    when :datetime
      form.datetime_local_field(field, field_options)
    when :checkbox
      checkbox_wrapper
    else
      form.text_field(field, field_options)
    end
  end

  def checkbox_wrapper
    content_tag :div, class: "flex items-center" do
      form.check_box(field, field_options.merge(class: "h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded")) +
      form.label(field, label_text, class: "ml-2 block text-sm text-gray-900")
    end
  end
end