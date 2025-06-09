class MetadataField < ApplicationRecord
  belongs_to :metadata_template
  has_many :metadata, dependent: :destroy
  
  validates :name, presence: true, uniqueness: { scope: :metadata_template_id }
  validates :field_type, presence: true, inclusion: { in: %w[string text integer date datetime boolean select file] }
  
  before_save :normalize_select_options, if: -> { field_type == 'select' }
  
  scope :required, -> { where(required: true) }
  scope :optional, -> { where(required: false) }
  
  def select_options_array
    return [] unless field_type == 'select'
    return [] if options.blank?
    
    if options.is_a?(String)
      options.split(',').map(&:strip)
    elsif options.is_a?(Array)
      options
    else
      []
    end
  end
  
  def html_input_type
    case field_type
    when 'string', 'text'
      'text'
    when 'integer'
      'number'
    when 'date'
      'date'
    when 'datetime'
      'datetime-local'
    when 'boolean'
      'checkbox'
    when 'select'
      'select'
    when 'file'
      'file'
    else
      'text'
    end
  end
  
  def validation_rules
    rules = (super || {}).with_indifferent_access
    rules[:required] = required if required
    rules
  end
  
  private
  
  def normalize_select_options
    if options.is_a?(String) && options.present?
      self.options = options.split(',').map(&:strip).join(',')
    end
  end
  
  # Virtual attribute for compatibility with tests
  def select_options=(value)
    self.options = value
  end
  
  def select_options
    options
  end
end