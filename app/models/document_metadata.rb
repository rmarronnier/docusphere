class DocumentMetadata < ApplicationRecord
  belongs_to :document
  belongs_to :metadata_field
  
  validates :value, presence: true
  
  def display_value
    case metadata_field.field_type
    when 'date'
      Date.parse(value).strftime('%d/%m/%Y')
    when 'datetime'
      DateTime.parse(value).strftime('%d/%m/%Y %H:%M')
    when 'boolean'
      value == 'true' ? 'Oui' : 'Non'
    else
      value
    end
  rescue
    value
  end
end