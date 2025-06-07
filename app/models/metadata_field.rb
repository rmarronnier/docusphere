class MetadataField < ApplicationRecord
  belongs_to :metadata_template
  has_many :metadata, dependent: :destroy
  
  validates :name, presence: true
  validates :field_type, inclusion: { in: %w[string text integer date datetime boolean select] }
  
  def select_options
    options&.split(',')&.map(&:strip) || []
  end
end