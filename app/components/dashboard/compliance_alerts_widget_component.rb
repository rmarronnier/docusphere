# frozen_string_literal: true

module Dashboard
  class ComplianceAlertsWidgetComponent < ViewComponent::Base
    include Turbo::FramesHelper

    def initialize(user:, max_alerts: 10)
      @user = user
      @max_alerts = max_alerts
      @alerts = load_compliance_alerts
      @upcoming_deadlines = load_upcoming_deadlines
      @stats = calculate_stats
    end

    private

    attr_reader :user, :max_alerts, :alerts, :upcoming_deadlines, :stats

    def load_compliance_alerts
      return [] unless user.active_profile&.profile_type == 'juridique'

      alerts = []

      # Documents expirés ou proches de l'expiration
      alerts += expiring_documents_alerts

      # Permis nécessitant attention
      alerts += permit_compliance_alerts if defined?(Immo::Promo::Permit)

      # Contrats nécessitant renouvellement
      alerts += contract_renewal_alerts

      # Validations juridiques en attente
      alerts += legal_validation_alerts

      # Trier par priorité et date
      alerts.sort_by { |a| [alert_priority_score(a[:priority]), a[:date]] }
            .first(max_alerts)
    end

    def expiring_documents_alerts
      Document
        .where('expiry_date IS NOT NULL')
        .where('expiry_date <= ?', 30.days.from_now)
        .where(status: ['active', 'published'])
        .map do |doc|
          {
            type: 'document_expiry',
            title: "Document expire bientôt",
            description: doc.name,
            date: doc.expiry_date,
            priority: expiry_priority(doc.expiry_date),
            action_path: helpers.ged_document_path(doc),
            action_label: 'Renouveler',
            icon: 'clock',
            color: expiry_color(doc.expiry_date)
          }
        end
    end

    def permit_compliance_alerts
      return [] unless defined?(Immo::Promo::Permit)

      Immo::Promo::Permit
        .where(status: ['pending', 'submitted'])
        .where('deadline <= ?', 14.days.from_now)
        .map do |permit|
          {
            type: 'permit_deadline',
            title: "Permis - Échéance proche",
            description: permit.name,
            date: permit.deadline,
            priority: deadline_priority(permit.deadline),
            action_path: helpers.immo_promo_engine.permit_path(permit),
            action_label: 'Consulter',
            icon: 'document-text',
            color: deadline_color(permit.deadline)
          }
        end
    end

    def contract_renewal_alerts
      Document
        .where(document_type: 'contract')
        .where('metadata ->> \'renewal_date\' IS NOT NULL')
        .where("(metadata ->> 'renewal_date')::date <= ?", 60.days.from_now)
        .map do |contract|
          renewal_date = Date.parse(contract.metadata['renewal_date'])
          {
            type: 'contract_renewal',
            title: "Contrat à renouveler",
            description: contract.name,
            date: renewal_date,
            priority: renewal_priority(renewal_date),
            action_path: helpers.ged_document_path(contract),
            action_label: 'Préparer renouvellement',
            icon: 'refresh',
            color: renewal_color(renewal_date)
          }
        end
    end

    def legal_validation_alerts
      ValidationRequest
        .where(validation_type: 'legal')
        .where(status: 'pending')
        .where(assigned_to: user)
        .map do |request|
          {
            type: 'legal_validation',
            title: "Validation juridique requise",
            description: request.validatable.name,
            date: request.created_at,
            priority: request.priority,
            action_path: helpers.ged_document_path(request.validatable),
            action_label: 'Valider',
            icon: 'shield-check',
            color: priority_color(request.priority)
          }
        end
    end

    def load_upcoming_deadlines
      deadlines = []

      # Échéances de conformité RGPD
      deadlines += gdpr_compliance_deadlines

      # Échéances fiscales
      deadlines += tax_compliance_deadlines

      # Assemblées et décisions importantes
      deadlines += corporate_deadlines

      deadlines.sort_by(&:date).first(5)
    end

    def gdpr_compliance_deadlines
      [
        {
          title: "Audit RGPD annuel",
          date: next_annual_date(Date.new(Date.current.year, 6, 1)),
          type: 'gdpr_audit',
          recurring: true
        },
        {
          title: "Mise à jour registre des traitements",
          date: Date.current.end_of_quarter,
          type: 'gdpr_register',
          recurring: true
        }
      ].select { |d| d[:date] <= 90.days.from_now }
    end

    def tax_compliance_deadlines
      [
        {
          title: "Déclaration TVA",
          date: Date.current.end_of_month,
          type: 'tax_vat',
          recurring: true
        },
        {
          title: "Liasse fiscale",
          date: Date.new(Date.current.year, 5, 15),
          type: 'tax_annual',
          recurring: false
        }
      ].select { |d| d[:date] > Date.current && d[:date] <= 60.days.from_now }
    end

    def corporate_deadlines
      [
        {
          title: "Assemblée générale annuelle",
          date: Date.new(Date.current.year, 6, 30),
          type: 'corporate_agm',
          recurring: false
        }
      ].select { |d| d[:date] > Date.current && d[:date] <= 90.days.from_now }
    end

    def calculate_stats
      {
        critical_alerts: alerts.count { |a| a[:priority] == 'high' },
        total_alerts: alerts.count,
        documents_expiring: alerts.count { |a| a[:type] == 'document_expiry' },
        pending_validations: alerts.count { |a| a[:type] == 'legal_validation' },
        upcoming_deadlines: upcoming_deadlines.count
      }
    end

    def alert_priority_score(priority)
      case priority
      when 'high' then 0
      when 'medium' then 1
      when 'low' then 2
      else 3
      end
    end

    def expiry_priority(date)
      days_until = (date - Date.current).to_i
      return 'high' if days_until <= 7
      return 'medium' if days_until <= 30
      'low'
    end

    def expiry_color(date)
      days_until = (date - Date.current).to_i
      return 'red' if days_until <= 7
      return 'orange' if days_until <= 30
      'yellow'
    end

    def deadline_priority(date)
      days_until = (date - Date.current).to_i
      return 'high' if days_until <= 3
      return 'medium' if days_until <= 7
      'low'
    end

    def deadline_color(date)
      days_until = (date - Date.current).to_i
      return 'red' if days_until <= 3
      return 'orange' if days_until <= 7
      'blue'
    end

    def renewal_priority(date)
      days_until = (date - Date.current).to_i
      return 'high' if days_until <= 30
      return 'medium' if days_until <= 60
      'low'
    end

    def renewal_color(date)
      days_until = (date - Date.current).to_i
      return 'red' if days_until <= 30
      return 'orange' if days_until <= 60
      'green'
    end

    def priority_color(priority)
      case priority
      when 'high' then 'red'
      when 'medium' then 'orange'
      when 'low' then 'yellow'
      else 'gray'
      end
    end

    def alert_icon_color(color)
      case color
      when 'red' then 'text-red-600'
      when 'orange' then 'text-orange-600'
      when 'yellow' then 'text-yellow-600'
      when 'blue' then 'text-blue-600'
      when 'green' then 'text-green-600'
      else 'text-gray-600'
      end
    end

    def alert_bg_color(color)
      case color
      when 'red' then 'bg-red-50'
      when 'orange' then 'bg-orange-50'
      when 'yellow' then 'bg-yellow-50'
      when 'blue' then 'bg-blue-50'
      when 'green' then 'bg-green-50'
      else 'bg-gray-50'
      end
    end

    def next_annual_date(base_date)
      return base_date if base_date > Date.current
      base_date.next_year
    end

    def days_until_text(date)
      days = (date - Date.current).to_i
      return "Aujourd'hui" if days == 0
      return "Demain" if days == 1
      return "Dans #{days} jours" if days > 0
      "En retard de #{days.abs} jours"
    end
  end
end