# frozen_string_literal: true

module Documents
  class DocumentShareModalComponent < ViewComponent::Base
    include Turbo::FramesHelper

    attr_reader :document, :modal_id

    def initialize(document:, modal_id: nil)
      @document = document
      @modal_id = modal_id || "share-modal-#{document.id}"
    end

    def render?
      document.present? && helpers.policy(document).share?
    end

    private

    def share_form_url
      helpers.ged_document_document_shares_path(document)
    end

    def permission_options
      [
        ['Lecture seule', 'read'],
        ['Écriture', 'write'],
        ['Administration', 'admin']
      ]
    end

    def suggested_users
      @suggested_users ||= begin
        # Get users from same organization excluding current user
        User.where(organization: document.space.organization)
            .where.not(id: helpers.current_user.id)
            .limit(5)
      end
    end

    def recent_shares
      @recent_shares ||= document.document_shares
                                 .includes(:shared_with)
                                 .order(created_at: :desc)
                                 .limit(5)
    end

    def share_button_classes
      "inline-flex items-center px-4 py-2 bg-blue-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-blue-700 active:bg-blue-900 focus:outline-none focus:border-blue-900 focus:ring ring-blue-300 disabled:opacity-25 transition ease-in-out duration-150"
    end

    def cancel_button_classes
      "inline-flex items-center px-4 py-2 bg-gray-300 border border-transparent rounded-md font-semibold text-xs text-gray-700 uppercase tracking-widest hover:bg-gray-400 active:bg-gray-500 focus:outline-none focus:border-gray-500 focus:ring ring-gray-300 disabled:opacity-25 transition ease-in-out duration-150"
    end

    def permission_badge_classes(permission)
      base_classes = "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
      
      case permission
      when 'read'
        "#{base_classes} bg-green-100 text-green-800"
      when 'write'
        "#{base_classes} bg-blue-100 text-blue-800"
      when 'admin'
        "#{base_classes} bg-red-100 text-red-800"
      else
        "#{base_classes} bg-gray-100 text-gray-800"
      end
    end
  end
end