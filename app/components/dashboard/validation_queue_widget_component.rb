# frozen_string_literal: true

module Dashboard
  class ValidationQueueWidgetComponent < ViewComponent::Base
    include Turbo::FramesHelper

    def initialize(user:, max_items: 10)
      @user = user
      @max_items = max_items
      @validation_requests = load_validation_requests
      @stats = calculate_stats
    end

    private

    attr_reader :user, :max_items
    
    def validatable_name(validatable)
      case validatable
      when Document
        validatable.title
      when Immo::Promo::Project
        validatable.name
      else
        "#{validatable.class.name} ##{validatable.id}"
      end
    end
    
    def status_color(status)
      case status
      when 'pending' then 'bg-yellow-100 text-yellow-800'
      when 'approved' then 'bg-green-100 text-green-800'
      when 'rejected' then 'bg-red-100 text-red-800'
      else 'bg-gray-100 text-gray-800'
      end
    end
    
    def due_date_label(due_date)
      if due_date < Time.current
        "En retard"
      elsif due_date < 1.day.from_now
        "Urgent"
      else
        "Échéance #{due_date.strftime('%d/%m')}"
      end
    end
    
    attr_reader :validation_requests, :stats

    def load_validation_requests
      # Documents en attente de validation pour la direction
      base_scope = ValidationRequest
        .includes(:validatable, :requester)
        .where(status: 'pending')
        .order(created_at: :asc)

      # Direction peut voir toutes les validations
      if user.active_profile&.profile_type == 'direction'
        # Les utilisateurs direction voient toutes les validations en attente
        # ou celles où ils sont validateurs via document_validations
        base_scope
          .left_joins(:document_validations)
          .where(
            'document_validations.validator_id = ? OR validation_requests.id IS NOT NULL',
            user.id
          )
          .distinct
      else
        # Les autres utilisateurs voient seulement leurs validations assignées
        base_scope
          .joins(:document_validations)
          .where(document_validations: { validator_id: user.id })
          .distinct
      end.limit(max_items)
    end

    def calculate_stats
      {
        total_pending: validation_requests.count,
        urgent: validation_requests.select { |vr| vr.due_date && vr.due_date < 1.day.from_now }.count,
        overdue: validation_requests.select { |vr| vr.due_date && vr.due_date < Time.current }.count,
        average_age: calculate_average_age
      }
    end

    def calculate_average_age
      return 0 if validation_requests.empty?

      total_days = validation_requests.sum do |request|
        (Date.current - request.created_at.to_date).to_i
      end

      (total_days.to_f / validation_requests.count).round(1)
    end

    def priority_color(priority)
      case priority
      when 'high' then 'text-red-600 bg-red-100'
      when 'medium' then 'text-yellow-600 bg-yellow-100'
      when 'low' then 'text-green-600 bg-green-100'
      else 'text-gray-600 bg-gray-100'
      end
    end

    def document_icon(validatable)
      return 'file' unless validatable.respond_to?(:file_content_type)

      case validatable.file_content_type
      when /pdf/ then 'file-pdf'
      when /word|docx/ then 'file-word'
      when /excel|xlsx/ then 'file-excel'
      when /image/ then 'file-image'
      else 'file'
      end
    end

    def validation_type_label(validation_type)
      case validation_type
      when 'content' then 'Contenu'
      when 'compliance' then 'Conformité'
      when 'financial' then 'Financier'
      when 'legal' then 'Juridique'
      when 'technical' then 'Technique'
      else validation_type.humanize
      end
    end

    def requester_name(requester)
      return 'Système' unless requester

      requester.full_name || requester.email
    end

    def time_ago_with_urgency(created_at)
      days_ago = (Date.current - created_at.to_date).to_i
      
      if days_ago > 7
        content_tag(:span, "il y a #{days_ago} jours", class: 'text-red-600 font-semibold')
      elsif days_ago > 3
        content_tag(:span, "il y a #{days_ago} jours", class: 'text-yellow-600')
      else
        "il y a #{days_ago} jour#{'s' if days_ago > 1}"
      end
    end

    def validation_path(validation_request)
      if validation_request.validatable_type == 'Document'
        helpers.ged_document_path(validation_request.validatable)
      else
        '#'
      end
    end

    def quick_actions_available?
      stats[:total_pending] > 0
    end

    def bulk_validation_enabled?
      user.active_profile&.profile_type == 'direction' && stats[:total_pending] > 1
    end
  end
end