# frozen_string_literal: true

module Dashboard
  class ClientDocumentsWidgetComponent < ViewComponent::Base
    include Turbo::FramesHelper

    def initialize(user:, max_clients: 5)
      @user = user
      @max_clients = max_clients
      @clients = load_user_clients
      @documents_by_client = load_documents_by_client
      @stats = calculate_stats
    end

    private

    attr_reader :user, :max_clients, :clients, :documents_by_client, :stats

    def load_user_clients
      return [] unless user.active_profile&.profile_type == 'commercial'

      # Charge les clients (stakeholders de type client) associés au commercial
      if defined?(Immo::Promo::Stakeholder)
        Immo::Promo::Stakeholder
          .where(stakeholder_type: 'client')
          .joins(:projects)
          .where(immo_promo_projects: { 
            id: Immo::Promo::ProjectStakeholder
              .where(stakeholder_id: user.id)
              .select(:project_id)
          })
          .distinct
          .order(updated_at: :desc)
          .limit(max_clients)
      else
        []
      end
    end

    def load_documents_by_client
      return {} if clients.empty?

      documents = {}
      clients.each do |client|
        # Documents partagés avec le client ou créés pour le client
        client_docs = Document
          .joins(:document_shares)
          .where(document_shares: { shared_with_id: client.id, shared_with_type: 'Immo::Promo::Stakeholder' })
          .or(Document.tagged_with("client:#{client.id}"))
          .or(Document.where("metadata ->> 'client_id' = ?", client.id.to_s))
          .includes(:uploaded_by, :tags)
          .order(created_at: :desc)
          .limit(5)

        documents[client.id] = {
          recent: client_docs,
          total_count: count_total_documents(client),
          proposals_count: count_proposals(client),
          contracts_count: count_contracts(client),
          shared_count: count_shared_documents(client)
        }
      end
      documents
    end

    def count_total_documents(client)
      Document
        .joins(:document_shares)
        .where(document_shares: { shared_with_id: client.id, shared_with_type: 'Immo::Promo::Stakeholder' })
        .count
    end

    def count_proposals(client)
      Document
        .where(document_type: 'proposal')
        .where("metadata ->> 'client_id' = ?", client.id.to_s)
        .count
    end

    def count_contracts(client)
      Document
        .where(document_type: 'contract')
        .where("metadata ->> 'client_id' = ?", client.id.to_s)
        .count
    end

    def count_shared_documents(client)
      DocumentShare
        .where(shared_with_id: client.id, shared_with_type: 'Immo::Promo::Stakeholder')
        .where(status: 'active')
        .count
    end

    def calculate_stats
      {
        total_clients: clients.count,
        total_documents: documents_by_client.values.sum { |d| d[:total_count] },
        active_proposals: documents_by_client.values.sum { |d| d[:proposals_count] },
        signed_contracts: count_signed_contracts,
        recent_shares: count_recent_shares
      }
    end

    def count_signed_contracts
      return 0 if clients.empty?

      Document
        .where(document_type: 'contract', status: 'signed')
        .where("metadata ->> 'client_id' IN (?)", clients.map(&:id).map(&:to_s))
        .count
    end

    def count_recent_shares
      return 0 if clients.empty?

      DocumentShare
        .where(shared_with: clients)
        .where('created_at > ?', 7.days.ago)
        .count
    end

    def client_status_badge(client)
      # Détermine le statut du client basé sur ses documents
      client_data = documents_by_client[client.id]
      
      if client_data[:contracts_count] > 0
        { label: 'Client actif', color: 'text-green-600 bg-green-100' }
      elsif client_data[:proposals_count] > 0
        { label: 'Proposition en cours', color: 'text-blue-600 bg-blue-100' }
      elsif client_data[:shared_count] > 0
        { label: 'Prospect qualifié', color: 'text-yellow-600 bg-yellow-100' }
      else
        { label: 'Nouveau prospect', color: 'text-gray-600 bg-gray-100' }
      end
    end

    def document_action_for_type(document)
      case document.document_type
      when 'proposal'
        { label: 'Envoyer', icon: 'paper-airplane', color: 'text-blue-600' }
      when 'contract'
        { label: 'Faire signer', icon: 'pencil', color: 'text-green-600' }
      when 'brochure'
        { label: 'Partager', icon: 'share', color: 'text-purple-600' }
      else
        { label: 'Consulter', icon: 'eye', color: 'text-gray-600' }
      end
    end

    def share_document_path(document, client)
      helpers.new_ged_document_document_share_path(
        document,
        shared_with_type: 'Immo::Promo::Stakeholder',
        shared_with_id: client.id
      )
    end

    def client_documents_path(client)
      helpers.ged_documents_path(
        shared_with_type: 'Immo::Promo::Stakeholder',
        shared_with_id: client.id
      )
    end

    def new_proposal_path(client)
      helpers.ged_new_document_path(
        document_type: 'proposal',
        metadata: { client_id: client.id, client_name: client.name }
      )
    end

    def client_contact_info(client)
      info = []
      info << client.email if client.email.present?
      info << client.phone if client.phone.present?
      info.join(' • ')
    end

    def last_interaction_time(client)
      last_doc = documents_by_client[client.id][:recent].first
      return 'Aucune interaction' unless last_doc

      "Dernière activité #{time_ago_in_words(last_doc.created_at)}"
    end
  end
end