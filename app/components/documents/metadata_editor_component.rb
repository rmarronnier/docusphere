# frozen_string_literal: true

class Documents::MetadataEditorComponent < ViewComponent::Base
  include Turbo::FramesHelper

  attr_reader :document, :current_user, :editing

  def initialize(document:, current_user:, editing: false)
    super
    @document = document
    @current_user = current_user
    @editing = editing
  end

  private

  def can_edit?
    return false unless current_user
    
    policy = Pundit.policy(current_user, document)
    policy.update?
  end

  def document_tags
    document.tags.pluck(:name).join(', ')
  end

  def metadata_fields
    return [] unless document.metadata_template

    document.metadata_template.metadata_fields.map do |field|
      {
        id: field.id,
        name: field.name,
        field_type: field.field_type,
        label: field.label,
        required: field.required,
        options: field.options,
        value: document.metadata&.dig(field.name)
      }
    end
  end

  def input_for_field(form, field)
    case field[:field_type]
    when 'text'
      form.text_field "metadata[#{field[:name]}]",
                     value: field[:value],
                     class: input_classes,
                     placeholder: field[:label],
                     required: field[:required]
    when 'textarea'
      form.text_area "metadata[#{field[:name]}]",
                    value: field[:value],
                    rows: 3,
                    class: input_classes,
                    placeholder: field[:label],
                    required: field[:required]
    when 'select'
      form.select "metadata[#{field[:name]}]",
                 options_for_select(field[:options] || [], field[:value]),
                 { prompt: "Sélectionner #{field[:label]}", include_blank: !field[:required] },
                 class: input_classes,
                 required: field[:required]
    when 'date'
      form.date_field "metadata[#{field[:name]}]",
                     value: field[:value],
                     class: input_classes,
                     required: field[:required]
    when 'number'
      form.number_field "metadata[#{field[:name]}]",
                       value: field[:value],
                       class: input_classes,
                       placeholder: field[:label],
                       required: field[:required]
    when 'boolean'
      content_tag(:div, class: "flex items-center") do
        concat form.check_box("metadata[#{field[:name]}]",
                            { checked: field[:value], class: "h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded" },
                            "true", "false")
        concat form.label("metadata[#{field[:name]}]", field[:label], class: "ml-2 block text-sm text-gray-900")
      end
    else
      form.text_field "metadata[#{field[:name]}]",
                     value: field[:value],
                     class: input_classes,
                     placeholder: field[:label]
    end
  end

  def input_classes
    "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
  end

  def label_classes
    "block text-sm font-medium text-gray-700"
  end
end