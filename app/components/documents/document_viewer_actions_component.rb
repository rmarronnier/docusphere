# frozen_string_literal: true

module Documents
  class DocumentViewerActionsComponent < ViewComponent::Base
    include ApplicationHelper
    
    def initialize(document:, user_profile:, context: nil)
      @document = document
      @user_profile = user_profile
      @context = context
    end
    
    private
    
    attr_reader :document, :user_profile, :context
    
    def profile_actions
      return [] unless user_profile
      
      case user_profile.profile_type
      when 'direction'
        direction_actions
      when 'chef_projet'
        project_manager_actions
      when 'juriste'
        legal_actions
      when 'architecte'
        architect_actions
      when 'commercial'
        commercial_actions
      when 'controleur'
        controller_actions
      when 'expert_technique'
        technical_expert_actions
      else
        []
      end
    end
    
    def direction_actions
      actions = []
      
      if document.pending_validation?
        actions << action_button(
          icon: 'check-circle',
          label: 'Approuver',
          path: helpers.ged_approve_document_path(document),
          method: :post,
          css_class: 'btn-success'
        )
        
        actions << action_button(
          icon: 'x-circle',
          label: 'Rejeter',
          path: helpers.ged_reject_document_path(document),
          method: :post,
          css_class: 'btn-danger',
          confirm: 'Êtes-vous sûr de vouloir rejeter ce document ?'
        )
      end
      
      actions << action_button(
        icon: 'user-plus',
        label: 'Assigner',
        path: '#',
        data: { action: 'click->modal#open', modal_target: 'assign-modal' }
      )
      
      actions << action_button(
        icon: 'flag',
        label: 'Définir priorité',
        path: '#',
        data: { action: 'click->modal#open', modal_target: 'priority-modal' }
      )
      
      actions
    end
    
    def project_manager_actions
      actions = []
      
      actions << action_button(
        icon: 'link',
        label: 'Lier au projet',
        path: '#',
        data: { action: 'click->modal#open', modal_target: 'link-project-modal' }
      )
      
      actions << action_button(
        icon: 'calendar',
        label: 'Assigner à phase',
        path: '#',
        data: { action: 'click->modal#open', modal_target: 'assign-phase-modal' }
      )
      
      if document.can_request_validation?(helpers.current_user)
        actions << action_button(
          icon: 'shield-check',
          label: 'Demander validation',
          path: helpers.ged_request_validation_document_path(document),
          method: :post
        )
      end
      
      actions << action_button(
        icon: 'users',
        label: 'Distribuer équipe',
        path: '#',
        data: { action: 'click->modal#open', modal_target: 'distribute-team-modal' }
      )
      
      actions
    end
    
    def legal_actions
      actions = []
      
      if document.requires_legal_review?
        actions << action_button(
          icon: 'shield-check',
          label: 'Valider conformité',
          path: helpers.ged_validate_compliance_document_path(document),
          method: :post,
          css_class: 'btn-success'
        )
      end
      
      actions << action_button(
        icon: 'clipboard-document-list',
        label: 'Notes juridiques',
        path: '#',
        data: { action: 'click->modal#open', modal_target: 'legal-notes-modal' }
      )
      
      if document.contract?
        actions << action_button(
          icon: 'pencil-square',
          label: 'Réviser contrat',
          path: helpers.ged_edit_document_path(document),
          css_class: 'btn-primary'
        )
      end
      
      actions << action_button(
        icon: 'archive-box',
        label: 'Archiver légalement',
        path: helpers.ged_legal_archive_document_path(document),
        method: :post,
        confirm: 'Archiver ce document selon les normes légales ?'
      )
      
      actions
    end
    
    def architect_actions
      actions = []
      
      if document.plan? || document.technical_drawing?
        actions << action_button(
          icon: 'pencil',
          label: 'Révision technique',
          path: helpers.ged_technical_review_document_path(document),
          method: :post
        )
        
        actions << action_button(
          icon: 'chat-bubble-bottom-center-text',
          label: 'Annoter plan',
          path: '#',
          data: { action: 'click->annotation#enable' }
        )
      end
      
      actions << action_button(
        icon: 'arrow-path',
        label: 'Demander modification',
        path: '#',
        data: { action: 'click->modal#open', modal_target: 'request-changes-modal' }
      )
      
      actions
    end
    
    def commercial_actions
      actions = []
      
      actions << action_button(
        icon: 'share',
        label: 'Partager avec client',
        path: '#',
        data: { action: 'click->modal#open', modal_target: 'share-client-modal' }
      )
      
      if document.pricing_document?
        actions << action_button(
          icon: 'document-plus',
          label: 'Créer proposition',
          path: helpers.new_proposal_from_document_path(document)
        )
      end
      
      actions << action_button(
        icon: 'currency-euro',
        label: 'Mettre à jour prix',
        path: '#',
        data: { action: 'click->modal#open', modal_target: 'update-pricing-modal' }
      )
      
      actions
    end
    
    def controller_actions
      actions = []
      
      if document.requires_validation?
        actions << action_button(
          icon: 'check',
          label: 'Valider',
          path: helpers.ged_validate_document_path(document),
          method: :post,
          css_class: 'btn-success'
        )
      end
      
      actions << action_button(
        icon: 'clipboard-document-check',
        label: 'Vérifier conformité',
        path: helpers.ged_check_compliance_document_path(document),
        method: :post
      )
      
      actions << action_button(
        icon: 'document-magnifying-glass',
        label: 'Ajouter à piste audit',
        path: helpers.add_to_audit_trail_document_path(document),
        method: :post
      )
      
      actions
    end
    
    def technical_expert_actions
      actions = []
      
      if document.technical_document?
        actions << action_button(
          icon: 'check-badge',
          label: 'Valider techniquement',
          path: helpers.ged_technical_validation_document_path(document),
          method: :post,
          css_class: 'btn-success'
        )
      end
      
      actions << action_button(
        icon: 'document-text',
        label: 'Ajouter notes techniques',
        path: '#',
        data: { action: 'click->modal#open', modal_target: 'technical-notes-modal' }
      )
      
      actions << action_button(
        icon: 'cpu-chip',
        label: 'Vérifier spécifications',
        path: helpers.ged_verify_specs_document_path(document),
        method: :post
      )
      
      actions
    end
    
    def action_button(icon:, label:, path:, method: :get, css_class: 'btn-secondary', data: {}, confirm: nil)
      {
        icon: icon,
        label: label,
        path: path,
        method: method,
        css_class: css_class,
        data: data,
        confirm: confirm
      }
    end
  end
end