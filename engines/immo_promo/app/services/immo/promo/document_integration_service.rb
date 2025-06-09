module Immo
  module Promo
    class DocumentIntegrationService
      attr_reader :document, :documentable
      
      def initialize(document, documentable = nil)
        @document = document
        @documentable = documentable || document.documentable
      end
      
      # Process document after upload
      def process_document
        return unless document && documentable
        
        # Extract metadata specific to real estate documents
        extract_real_estate_metadata
        
        # Auto-categorize based on content
        auto_categorize_document
        
        # Create automatic relationships
        create_document_relationships
        
        # Check compliance requirements
        check_compliance_requirements
        
        # Trigger notifications
        notify_relevant_stakeholders
        
        true
      rescue => e
        Rails.logger.error "Document integration failed: #{e.message}"
        false
      end
      
      # Extract real estate specific metadata
      def extract_real_estate_metadata
        return unless document.extracted_entities.present?
        
        entities = document.extracted_entities
        
        # Extract permit numbers
        if entities['permit_numbers'].present?
          create_or_update_permits(entities['permit_numbers'])
        end
        
        # Extract amounts for budget tracking
        if entities['amounts'].present? && documentable.is_a?(Project)
          update_budget_tracking(entities['amounts'])
        end
        
        # Extract dates for timeline management
        if entities['dates'].present?
          update_timeline_events(entities['dates'])
        end
        
        # Extract contractor/supplier names
        if entities['organizations'].present?
          link_to_stakeholders(entities['organizations'])
        end
      end
      
      # Auto-categorize document based on AI classification
      def auto_categorize_document
        return unless document.ai_classification.present?
        
        # Map AI classifications to document categories
        category_mapping = {
          'building_permit' => 'permit',
          'construction_permit' => 'permit',
          'architectural_plan' => 'plan',
          'floor_plan' => 'plan',
          'quote' => 'financial',
          'invoice' => 'financial',
          'contract' => 'legal',
          'technical_report' => 'technical',
          'site_report' => 'technical',
          'inspection_report' => 'technical'
        }
        
        if category = category_mapping[document.ai_classification]
          document.update(document_category: category)
        end
      end
      
      # Create automatic relationships based on document content
      def create_document_relationships
        case document.document_category
        when 'permit'
          link_to_permit_phase
        when 'financial'
          link_to_budget_line
        when 'technical'
          link_to_current_phase
        when 'contract'
          link_to_stakeholder_contract
        end
      end
      
      # Check if document fulfills compliance requirements
      def check_compliance_requirements
        return unless documentable.is_a?(Project)
        
        project = documentable
        current_phase = project.phases.in_progress.first
        
        return unless current_phase
        
        # Check required documents for current phase
        required_docs = required_documents_for_phase(current_phase)
        existing_categories = project.documents.pluck(:document_category).uniq
        
        # Mark phase compliance if all required documents are present
        if (required_docs - existing_categories).empty?
          current_phase.update(compliance_status: 'complete')
          
          NotificationService.new.create_notification(
            user: project.project_manager,
            notification_type: 'phase_compliance_complete',
            title: "Conformité documentaire complète",
            message: "Tous les documents requis pour la phase #{current_phase.name} sont présents.",
            metadata: {
              project_id: project.id,
              phase_id: current_phase.id
            }
          )
        end
      end
      
      # Notify relevant stakeholders about new document
      def notify_relevant_stakeholders
        users_to_notify = determine_notification_recipients
        
        users_to_notify.each do |user|
          NotificationService.new.create_notification(
            user: user,
            notification_type: 'document_uploaded',
            title: "Nouveau document ajouté",
            message: "#{document.title} a été ajouté au projet #{documentable.name}",
            metadata: {
              document_id: document.id,
              project_id: documentable.id,
              document_category: document.document_category
            }
          )
        end
      end
      
      private
      
      def create_or_update_permits(permit_numbers)
        return unless documentable.is_a?(Project)
        
        permit_numbers.each do |permit_number|
          permit = documentable.permits.find_or_initialize_by(
            reference_number: permit_number
          )
          
          if permit.new_record?
            permit.update!(
              permit_type: 'construction',
              status: 'submitted',
              submitted_date: Date.current,
              organization: documentable.organization
            )
          end
          
          # Attach document to permit
          document.update(documentable: permit) if document.documentable_type == 'Immo::Promo::Project'
        end
      end
      
      def update_budget_tracking(amounts)
        return unless documentable.respond_to?(:budgets)
        
        # Extract largest amount as potential budget update
        amount = amounts.map { |a| a.to_f }.max
        
        if amount > 0 && document.document_category == 'financial'
          # This could trigger a budget adjustment workflow
          Rails.logger.info "Potential budget impact detected: #{amount}"
        end
      end
      
      def update_timeline_events(dates)
        return unless documentable.respond_to?(:milestones)
        
        # Parse dates and create milestones if needed
        dates.each do |date_str|
          begin
            date = Date.parse(date_str)
            
            # Create milestone for future dates
            if date > Date.current
              documentable.milestones.find_or_create_by(
                target_date: date,
                name: "Échéance - #{document.title}",
                milestone_type: 'deadline'
              )
            end
          rescue
            # Invalid date format
          end
        end
      end
      
      def link_to_stakeholders(organizations)
        return unless documentable.respond_to?(:stakeholders)
        
        organizations.each do |org_name|
          stakeholder = documentable.stakeholders.find_by(
            "company_name ILIKE ? OR name ILIKE ?", 
            "%#{org_name}%", 
            "%#{org_name}%"
          )
          
          if stakeholder && document.document_category == 'contract'
            # This document might be a contract with this stakeholder
            stakeholder.documents << document unless stakeholder.documents.include?(document)
          end
        end
      end
      
      def link_to_permit_phase
        return unless documentable.is_a?(Project)
        
        permit_phase = documentable.phases.find_by(phase_type: 'permits')
        if permit_phase && !permit_phase.documents.include?(document)
          document.update(documentable: permit_phase)
        end
      end
      
      def link_to_budget_line
        return unless documentable.respond_to?(:budgets)
        
        # Financial documents could be linked to specific budget lines
        # based on extracted metadata
      end
      
      def link_to_current_phase
        return unless documentable.is_a?(Project)
        
        current_phase = documentable.phases.in_progress.first
        if current_phase && document.documentable == documentable
          # Move document to current phase for better organization
          document.update(documentable: current_phase)
        end
      end
      
      def link_to_stakeholder_contract
        # Contract documents should be linked to the relevant stakeholder
        if document.extracted_entities['organizations'].present?
          link_to_stakeholders(document.extracted_entities['organizations'])
        end
      end
      
      def required_documents_for_phase(phase)
        case phase.phase_type
        when 'permits'
          ['permit', 'plan', 'administrative']
        when 'construction'
          ['contract', 'technical', 'financial']
        when 'studies'
          ['technical', 'plan']
        when 'delivery'
          ['technical', 'administrative', 'legal']
        else
          []
        end
      end
      
      def determine_notification_recipients
        recipients = []
        
        # Always notify project manager
        if documentable.respond_to?(:project_manager)
          recipients << documentable.project_manager
        elsif documentable.respond_to?(:project)
          recipients << documentable.project.project_manager
        end
        
        # Notify based on document category
        case document.document_category
        when 'permit'
          # Notify architects and permit managers
          if documentable.respond_to?(:stakeholders)
            recipients += documentable.stakeholders
                                    .where(stakeholder_type: 'architect')
                                    .includes(:user)
                                    .map(&:user)
                                    .compact
          end
        when 'financial'
          # Notify financial controllers
          recipients += User.joins(:user_groups)
                           .where(user_groups: { name: 'Finance' })
                           .where(organization: documentable.organization)
        when 'technical'
          # Notify technical team
          if documentable.respond_to?(:stakeholders)
            recipients += documentable.stakeholders
                                    .where(stakeholder_type: ['contractor', 'engineer'])
                                    .includes(:user)
                                    .map(&:user)
                                    .compact
          end
        end
        
        recipients.uniq
      end
    end
  end
end