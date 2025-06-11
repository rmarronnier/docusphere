module Immo
  module Promo
    class Risk < ApplicationRecord
      self.table_name = 'immo_promo_risks'

      audited

      belongs_to :project, class_name: 'Immo::Promo::Project'
      belongs_to :owner, class_name: 'User', optional: true
      
      # Documents polymorphic association
      has_many :documents, as: :documentable, dependent: :destroy

      # Aliases for compatibility
      alias_attribute :identified_by, :owner
      alias_attribute :assigned_to, :owner
      alias_attribute :risk_type, :category

      validates :title, presence: true
      validates :description, presence: true
      validates :category, presence: true
      validates :probability, presence: true
      validates :impact, presence: true
      validates :status, presence: true

      # Declare attribute type for enum
      attribute :category, :string

      enum category: {
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
        very_low: 1,
        low: 2,
        medium: 3,
        high: 4,
        very_high: 5
      }, _prefix: true

      enum impact: {
        very_low: 1,
        low: 2,
        medium: 3,
        high: 4,
        very_high: 5
      }, _prefix: true

      enum status: {
        identified: 'identified',
        assessed: 'assessed',
        mitigated: 'mitigated',
        monitored: 'monitored',
        closed: 'closed'
      }

      scope :active, -> { where.not(status: 'closed') }
      scope :high_priority, -> { where(probability: [ 4, 5 ], impact: [ 4, 5 ]) }
      scope :by_type, ->(type) { where(category: type) }
      
      # Business associations
      def impacted_milestones
        return Immo::Promo::Milestone.none unless project
        milestone_types = milestone_types_for_risk_category
        project.milestones.where(milestone_type: milestone_types)
      end
      
      def related_permits
        return Immo::Promo::Permit.none unless project || category != 'regulatory'
        project.permits.where(permit_type: permit_types_for_risk_category)
      end
      
      def stakeholders_involved
        return Immo::Promo::Stakeholder.none unless project
        project.stakeholders.where(stakeholder_type: stakeholder_types_for_risk_category)
      end
      
      def mitigation_tasks
        return Immo::Promo::Task.none unless project
        # Tasks liées à la mitigation de ce risque (basé sur description ou tags)
        project.tasks.where("description ILIKE ? OR name ILIKE ?", "%#{title}%", "%mitigation%")
      end

      def risk_score
        return 0 unless probability && impact
        # Get the numeric values directly from the enum mapping
        prob_val = self.class.probabilities[probability]
        impact_val = self.class.impacts[impact]
        return 0 unless prob_val && impact_val
        prob_val * impact_val
      end

      def risk_level
        case risk_score
        when 1..4 then 'low'
        when 5..12 then 'medium'
        when 13..20 then 'high'
        when 21..25 then 'critical'
        end
      end

      # Alias for test compatibility
      def severity_level
        level = risk_level
        level ? level.to_sym : :unknown
      end

      def is_critical?
        risk_level == 'critical'
      end

      def is_high_priority?
        [ 'high', 'critical' ].include?(risk_level)
      end

      def days_since_identification
        (Date.current - created_at.to_date).to_i
      end

      def requires_immediate_attention?
        is_critical? && status == 'identified'
      end
      
      private
      
      def milestone_types_for_risk_category
        case category
        when 'regulatory' then ['permit_submission', 'permit_approval']
        when 'technical' then ['construction_start', 'construction_completion']
        when 'financial' then ['delivery']
        when 'timeline' then ['permit_approval', 'construction_start', 'delivery']
        when 'legal' then ['permit_submission', 'legal_deadline']
        when 'environmental' then ['permit_submission', 'construction_start']
        else ['delivery']
        end
      end
      
      def permit_types_for_risk_category
        case category
        when 'regulatory' then ['urban_planning', 'construction', 'environmental']
        when 'environmental' then ['environmental', 'construction']
        when 'technical' then ['construction']
        else []
        end
      end
      
      def stakeholder_types_for_risk_category
        case category
        when 'technical' then ['architect', 'engineer', 'contractor']
        when 'financial' then ['developer', 'financier']
        when 'legal' then ['legal_advisor', 'notary']
        when 'regulatory' then ['consultant', 'architect']
        when 'environmental' then ['environmental_consultant', 'engineer']
        else ['project_manager']
        end
      end
    end
  end
end
