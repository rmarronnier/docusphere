# frozen_string_literal: true

class Documents::VersionComparisonComponent < ViewComponent::Base
  include Turbo::FramesHelper

  attr_reader :document, :version1, :version2, :current_user

  def initialize(document:, version1: nil, version2: nil, current_user:)
    super
    @document = document
    @current_user = current_user
    @version1 = version1 || document.versions.order(created_at: :desc).second
    @version2 = version2 || document.versions.order(created_at: :desc).first
  end

  private

  def can_compare?
    version1.present? && version2.present? && version1 != version2
  end

  def version_options
    document.versions.order(created_at: :desc).map do |version|
      [
        "Version #{version.id} - #{version.created_at.strftime('%d/%m/%Y %H:%M')}",
        version.id
      ]
    end
  end

  def format_changes(version)
    return {} unless version.object_changes.present?
    
    changes = version.object_changes
    formatted = {}
    
    changes.each do |field, values|
      next if field.in?(%w[updated_at processing_metadata])
      
      formatted[humanize_field(field)] = {
        old: format_value(values[0]),
        new: format_value(values[1])
      }
    end
    
    formatted
  end

  def humanize_field(field)
    field.humanize.capitalize
  end

  def format_value(value)
    case value
    when nil
      "(vide)"
    when true, false
      value ? "Oui" : "Non"
    when Time, DateTime
      value.strftime('%d/%m/%Y %H:%M')
    when Hash, Array
      value.to_json
    else
      value.to_s
    end
  end

  def version_metadata(version)
    {
      author: version.whodunnit ? User.find_by(id: version.whodunnit)&.display_name : "Système",
      date: version.created_at.strftime('%d/%m/%Y à %H:%M'),
      event: translate_event(version.event)
    }
  end

  def translate_event(event)
    case event
    when 'create' then 'Création'
    when 'update' then 'Modification'
    when 'destroy' then 'Suppression'
    else event
    end
  end

  def highlight_difference(field, old_value, new_value)
    if old_value == new_value
      content_tag(:span, new_value, class: "text-gray-700")
    else
      content_tag(:span) do
        concat content_tag(:del, old_value, class: "text-red-600 line-through mr-2") if old_value.present?
        concat content_tag(:ins, new_value, class: "text-green-600 font-semibold")
      end
    end
  end
end