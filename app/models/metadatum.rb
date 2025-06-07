class Metadatum < ApplicationRecord
  belongs_to :metadatable, polymorphic: true
  belongs_to :metadata_field, optional: true
  
  # Validation conditionnelle
  validates :key, presence: true, if: -> { metadata_field.blank? }
  validates :value, presence: true
  
  # Unicité selon le type de métadonnée
  validates :key, uniqueness: { scope: [:metadatable_type, :metadatable_id] }, 
            if: -> { metadata_field.blank? }
  validates :metadata_field_id, uniqueness: { scope: [:metadatable_type, :metadatable_id] }, 
            if: -> { metadata_field.present? }
  
  # Validation du type de donnée si metadata_field est présent
  validate :validate_value_type, if: -> { metadata_field.present? }
  
  scope :for_key, ->(key) { where(key: key) }
  scope :structured, -> { where.not(metadata_field_id: nil) }
  scope :flexible, -> { where(metadata_field_id: nil) }
  
  # Méthode pour afficher la valeur formatée
  def display_value
    return value unless metadata_field.present?
    
    case metadata_field.field_type
    when 'date'
      Date.parse(value).strftime('%d/%m/%Y')
    when 'datetime'
      DateTime.parse(value).strftime('%d/%m/%Y %H:%M')
    when 'boolean'
      value == 'true' ? 'Oui' : 'Non'
    when 'integer'
      value.to_i
    else
      value
    end
  rescue
    value
  end
  
  # Nom de la métadonnée (depuis key ou metadata_field)
  def name
    metadata_field.present? ? metadata_field.name : key
  end
  
  private
  
  def validate_value_type
    return unless metadata_field.present?
    
    case metadata_field.field_type
    when 'integer'
      errors.add(:value, 'doit être un nombre entier') unless value =~ /\A\d+\z/
    when 'date'
      begin
        Date.parse(value)
      rescue
        errors.add(:value, 'doit être une date valide')
      end
    when 'datetime'
      begin
        DateTime.parse(value)
      rescue
        errors.add(:value, 'doit être une date/heure valide')
      end
    when 'boolean'
      errors.add(:value, 'doit être true ou false') unless ['true', 'false'].include?(value)
    when 'select'
      if metadata_field.options.present? && !metadata_field.options.include?(value)
        errors.add(:value, "doit être l'une des options: #{metadata_field.options.join(', ')}")
      end
    end
  end
end
