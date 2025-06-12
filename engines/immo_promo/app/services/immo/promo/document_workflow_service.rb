# frozen_string_literal: true

module Immo
  module Promo
    class DocumentWorkflowService
      def initialize(project, user)
        @project = project
        @user = user
      end

      # Upload document with project context
      def upload_document_with_context(file, category:, phase_id: nil, title: nil, description: nil)
        document = @project.attach_document(
          file,
          category: category,
          user: @user,
          title: title || file.original_filename,
          description: description
        )

        # Add phase context if provided
        if phase_id.present?
          phase = @project.phases.find(phase_id)
          link_document_to_phase(document, phase)
        end

        # Add project-specific metadata
        add_project_metadata(document)

        # Trigger project-specific validations if needed
        trigger_validation_workflows(document, category)

        document
      end

      # Batch upload for project phases
      def batch_upload_for_phase(files, phase_id, category: 'technical')
        phase = @project.phases.find(phase_id)
        documents = []

        files.each do |file|
          document = upload_document_with_context(
            file,
            category: category,
            phase_id: phase_id,
            title: generate_contextual_title(file, phase, category)
          )
          documents << document
        end

        # Generate phase completion report if all required documents are uploaded
        check_phase_document_completeness(phase) if documents.any?

        documents
      end

      # Share project documents with stakeholders
      def share_with_project_stakeholders(document_ids, stakeholder_roles: ['all'], permission_level: 'read')
        stakeholders = filter_stakeholders_by_role(stakeholder_roles)
        shares = []

        stakeholders.each do |stakeholder|
          shares.concat(
            @project.share_documents_with_stakeholder(
              stakeholder,
              document_ids,
              permission_level: permission_level,
              user: @user
            )
          )
        end

        # Send notification to stakeholders
        notify_stakeholders_about_documents(stakeholders, document_ids)

        shares
      end

      # Request validation for critical project documents
      def request_project_validation(document_ids, validator_roles: ['direction'], priority: 'medium')
        validators = find_validators_by_role(validator_roles)
        validations = []

        document_ids.each do |doc_id|
          document = @project.documents.find(doc_id)
          
          validation = document.validation_requests.create!(
            requester: @user,
            assigned_to: validators.sample, # Distribute among available validators
            status: 'pending',
            priority: priority,
            due_date: calculate_validation_due_date(document, priority),
            notes: generate_validation_context(document)
          )
          
          validations << validation
        end

        # Send notifications to validators
        notify_validators_about_pending_documents(validators, validations)

        validations
      end

      # Generate compliance report for project phase
      def generate_phase_compliance_report(phase_id)
        phase = @project.phases.find(phase_id)
        required_docs = required_documents_for_phase(phase)
        
        compliance_data = {
          phase_name: phase.name,
          phase_type: phase.phase_type,
          required_documents: required_docs,
          compliance_status: {},
          missing_documents: [],
          pending_validations: [],
          recommendations: []
        }

        required_docs.each do |doc_type|
          documents = phase.documents.where(document_category: doc_type)
          
          compliance_data[:compliance_status][doc_type] = {
            present: documents.any?,
            count: documents.count,
            approved: documents.joins(:validation_requests)
                              .where(validation_requests: { status: 'approved' })
                              .count,
            latest_version: documents.maximum(:updated_at)
          }

          if documents.empty?
            compliance_data[:missing_documents] << doc_type
          end

          pending_validations = documents.joins(:validation_requests)
                                        .where(validation_requests: { status: 'pending' })
          
          if pending_validations.any?
            compliance_data[:pending_validations] << {
              document_type: doc_type,
              count: pending_validations.count,
              oldest_request: pending_validations.minimum('validation_requests.created_at')
            }
          end
        end

        # Generate recommendations
        compliance_data[:recommendations] = generate_compliance_recommendations(compliance_data)

        compliance_data
      end

      # Automated document categorization for ImmoPromo projects
      def auto_categorize_document(file)
        filename = file.original_filename.downcase
        
        category = case filename
                  when /plan|dwg|blueprint|architect/
                    'plan'
                  when /permit|authorization|autorisation|permis/
                    'permit'
                  when /contract|contrat|agreement|accord/
                    'legal'
                  when /budget|financial|financier|devis/
                    'financial'
                  when /technical|technique|specification/
                    'technical'
                  when /administrative|admin|declaration/
                    'administrative'
                  when /project|projet|presentation/
                    'project'
                  else
                    'project' # Default category
                  end

        # Add suggested tags based on project type and phase
        suggested_tags = generate_suggested_tags(category)

        {
          category: category,
          suggested_tags: suggested_tags,
          suggested_title: generate_suggested_title(file, category)
        }
      end

      private

      attr_reader :project, :user

      def link_document_to_phase(document, phase)
        # Create metadata linking document to phase
        document.metadata.create!(
          key: 'phase_id',
          value: phase.id.to_s,
          metadata_type: 'phase_association'
        )

        document.metadata.create!(
          key: 'phase_name',
          value: phase.name,
          metadata_type: 'phase_association'
        )
      end

      def add_project_metadata(document)
        document.metadata.create!(
          key: 'project_id',
          value: @project.id.to_s,
          metadata_type: 'project_association'
        )

        document.metadata.create!(
          key: 'project_type',
          value: @project.project_type,
          metadata_type: 'project_association'
        )

        document.metadata.create!(
          key: 'project_status',
          value: @project.status,
          metadata_type: 'project_association'
        )
      end

      def trigger_validation_workflows(document, category)
        # Auto-request validation for critical document types
        critical_categories = ['permit', 'legal', 'financial']
        
        if critical_categories.include?(category)
          request_project_validation([document.id], priority: 'high')
        end
      end

      def generate_contextual_title(file, phase, category)
        base_name = File.basename(file.original_filename, '.*')
        "#{@project.name} - #{phase.name} - #{category.humanize} - #{base_name}"
      end

      def filter_stakeholders_by_role(stakeholder_roles)
        if stakeholder_roles.include?('all')
          @project.stakeholders.active
        else
          @project.stakeholders.active.where(role: stakeholder_roles)
        end
      end

      def find_validators_by_role(validator_roles)
        organization_users = @project.organization.users.joins(:user_profiles)
        
        validators = []
        validator_roles.each do |role|
          role_users = organization_users.where(user_profiles: { profile_type: role, active: true })
          validators.concat(role_users.to_a)
        end
        
        validators.uniq
      end

      def calculate_validation_due_date(document, priority)
        case priority
        when 'high' then 2.business_days.from_now
        when 'medium' then 5.business_days.from_now
        when 'low' then 10.business_days.from_now
        else 5.business_days.from_now
        end
      end

      def generate_validation_context(document)
        "Document de projet #{@project.name} (#{@project.project_type.humanize}) - " \
        "Catégorie: #{document.document_category.humanize} - " \
        "Statut projet: #{@project.status.humanize}"
      end

      def required_documents_for_phase(phase)
        case phase.phase_type
        when 'permits'
          %w[permit administrative legal plan]
        when 'studies'
          %w[technical plan project]
        when 'construction'
          %w[permit technical plan administrative]
        when 'delivery'
          %w[administrative legal technical]
        else
          %w[project technical]
        end
      end

      def generate_compliance_recommendations(compliance_data)
        recommendations = []

        compliance_data[:missing_documents].each do |doc_type|
          recommendations << {
            type: 'missing_document',
            priority: 'high',
            message: "Document #{doc_type.humanize} manquant pour la phase #{compliance_data[:phase_name]}",
            action: "Uploader le document #{doc_type.humanize}"
          }
        end

        compliance_data[:pending_validations].each do |validation_info|
          days_pending = (Time.current - validation_info[:oldest_request]).to_i / 1.day
          
          if days_pending > 5
            recommendations << {
              type: 'overdue_validation',
              priority: 'medium',
              message: "Validation en attente depuis #{days_pending} jours pour #{validation_info[:document_type].humanize}",
              action: "Relancer les validateurs"
            }
          end
        end

        recommendations
      end

      def generate_suggested_tags(category)
        base_tags = [@project.project_type, @project.status]
        
        category_tags = case category
                       when 'permit'
                         ['permis', 'réglementation', 'autorisation']
                       when 'technical'
                         ['technique', 'spécifications', 'études']
                       when 'financial'
                         ['budget', 'coûts', 'financement']
                       when 'legal'
                         ['juridique', 'contrat', 'droit']
                       when 'plan'
                         ['plans', 'architecture', 'conception']
                       else
                         ['général']
                       end

        (base_tags + category_tags).uniq
      end

      def generate_suggested_title(file, category)
        base_name = File.basename(file.original_filename, '.*')
        "#{@project.name} - #{category.humanize} - #{base_name}"
      end

      def check_phase_document_completeness(phase)
        required_docs = required_documents_for_phase(phase)
        missing_docs = required_docs - phase.documents.pluck(:document_category).uniq

        if missing_docs.empty?
          # Phase has all required documents - send notification
          notify_phase_document_completeness(phase)
        end
      end

      def notify_stakeholders_about_documents(stakeholders, document_ids)
        # Implementation would depend on notification system
        # For now, just log the action
        Rails.logger.info "Documents #{document_ids.join(', ')} shared with #{stakeholders.count} stakeholders for project #{@project.name}"
      end

      def notify_validators_about_pending_documents(validators, validations)
        # Implementation would depend on notification system
        Rails.logger.info "#{validations.count} validation requests sent to #{validators.count} validators for project #{@project.name}"
      end

      def notify_phase_document_completeness(phase)
        Rails.logger.info "Phase #{phase.name} has all required documents for project #{@project.name}"
      end
    end
  end
end