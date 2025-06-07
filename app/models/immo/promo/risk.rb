class Immo::Promo::Risk < ApplicationRecord
  self.table_name = 'immo_promo_risks'
  
  audited

  belongs_to :project, class_name: 'Immo::Promo::Project'
  belongs_to :identified_by, class_name: 'User'
  belongs_to :assigned_to, class_name: 'User', optional: true

  validates :title, presence: true
  validates :risk_type, presence: true
  validates :probability, presence: true
  validates :impact, presence: true
  validates :status, presence: true

  enum risk_type: {
    technical: 'technical',
    financial: 'financial',
    legal: 'legal',
    regulatory: 'regulatory',
    environmental: 'environmental',
    timeline: 'timeline',
    quality: 'quality',
    external: 'external'
  }

  enum probability: {
    very_low: 'very_low',
    low: 'low', 
    medium: 'medium',
    high: 'high',
    very_high: 'very_high'
  }, _prefix: true

  enum impact: {
    very_low: 'very_low',
    low: 'low',
    medium: 'medium', 
    high: 'high',
    very_high: 'very_high'
  }, _prefix: true

  enum status: {
    identified: 'identified',
    assessed: 'assessed',
    mitigated: 'mitigated',
    monitored: 'monitored',
    closed: 'closed'
  }

  scope :active, -> { where.not(status: 'closed') }
  scope :high_priority, -> { where(probability: ['high', 'very_high'], impact: ['high', 'very_high']) }
  scope :by_type, ->(type) { where(risk_type: type) }

  PROBABILITY_SCORES = {
    'very_low' => 1,
    'low' => 2,
    'medium' => 3,
    'high' => 4,
    'very_high' => 5
  }.freeze

  IMPACT_SCORES = {
    'very_low' => 1,
    'low' => 2,
    'medium' => 3,
    'high' => 4,
    'very_high' => 5
  }.freeze

  def risk_score
    PROBABILITY_SCORES[probability] * IMPACT_SCORES[impact]
  end

  def risk_level
    case risk_score
    when 1..4 then 'low'
    when 5..12 then 'medium'
    when 13..20 then 'high'
    when 21..25 then 'critical'
    end
  end

  def is_critical?
    risk_level == 'critical'
  end

  def is_high_priority?
    ['high', 'critical'].include?(risk_level)
  end

  def days_since_identification
    (Date.current - created_at.to_date).to_i
  end

  def requires_immediate_attention?
    is_critical? && status == 'identified'
  end
end