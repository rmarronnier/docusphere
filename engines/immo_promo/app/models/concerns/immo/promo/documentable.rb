module Immo
  module Promo
    module Documentable
      extend ActiveSupport::Concern

      included do
        # Polymorphic association with the main Document model
        has_many :documents, as: :documentable, class_name: '::Document', dependent: :destroy
        
        # Specific document categories for ImmoPromo
        has_many :project_documents, -> { where(document_category: 'project') }, 
                 as: :documentable, class_name: '::Document'
        has_many :technical_documents, -> { where(document_category: 'technical') }, 
                 as: :documentable, class_name: '::Document'
        has_many :administrative_documents, -> { where(document_category: 'administrative') }, 
                 as: :documentable, class_name: '::Document'
        has_many :financial_documents, -> { where(document_category: 'financial') }, 
                 as: :documentable, class_name: '::Document'
        has_many :legal_documents, -> { where(document_category: 'legal') }, 
                 as: :documentable, class_name: '::Document'
        has_many :permit_documents, -> { where(document_category: 'permit') }, 
                 as: :documentable, class_name: '::Document'
        has_many :plan_documents, -> { where(document_category: 'plan') }, 
                 as: :documentable, class_name: '::Document'

        # Document validation workflows specific to ImmoPromo
        has_many :document_validations, through: :documents, source: :document_validations
        has_many :validation_requests, through: :documents, source: :validation_requests

        # Version management
        has_many :document_versions, through: :documents, source: :document_versions

        # Document shares for stakeholder collaboration
        has_many :document_shares, through: :documents, source: :document_shares
      end

      # Document upload helper methods
      def attach_document(file, category: 'project', user:, title: nil, description: nil)
        document = documents.create!(
          title: title || file.original_filename,
          description: description,
          uploaded_by: user,
          space: default_document_space,
          folder: default_document_folder,
          document_category: category,
          documentable: self
        )
        
        document.file.attach(file)
        
        # Trigger document integration service
        DocumentIntegrationService.new(document, self).process_document
        
        document
      end

      def attach_multiple_documents(files, category: 'project', user:)
        documents = []
        files.each do |file|
          documents << attach_document(file, category: category, user: user)
        end
        documents
      end

      # Document filtering and organization
      def documents_by_category(category)
        documents.where(document_category: category)
      end

      def documents_by_status(status)
        documents.where(status: status)
      end

      def documents_requiring_validation
        documents.joins(:validation_requests)
                 .where(validation_requests: { status: 'pending' })
                 .distinct
      end

      def approved_documents
        documents.joins(:validation_requests)
                 .where(validation_requests: { status: 'approved' })
                 .distinct
      end

      # Document version management
      def latest_document_versions
        documents.joins(:document_versions)
                 .where(document_versions: { is_current: true })
                 .distinct
      end

      def document_version_history(document_id)
        documents.find(document_id).document_versions.order(version_number: :desc)
      end

      # Document sharing with stakeholders
      def share_documents_with_stakeholder(stakeholder, document_ids, permission_level: 'read', user:)
        shares = []
        document_ids.each do |doc_id|
          document = documents.find(doc_id)
          share = document.document_shares.create!(
            shared_with_user: stakeholder.respond_to?(:user) ? stakeholder.user : nil,
            shared_with_email: stakeholder.email,
            permission_level: permission_level,
            shared_by: user,
            expires_at: 30.days.from_now
          )
          shares << share
        end
        shares
      end

      def share_document_category_with_stakeholders(category, stakeholders, permission_level: 'read', user:)
        document_ids = documents_by_category(category).pluck(:id)
        shares = []
        stakeholders.each do |stakeholder|
          shares.concat(share_documents_with_stakeholder(stakeholder, document_ids, permission_level: permission_level, user: user))
        end
        shares
      end

      # Document validation workflows
      def request_document_validation(document_ids, validators:, requester:, min_validations: 1)
        validations = []
        document_ids.each do |doc_id|
          document = documents.find(doc_id)
          validation = document.request_validation(
            requester: requester,
            validators: validators,
            min_validations: min_validations
          )
          validations << validation
        end
        validations
      end

      # Document authorization helpers
      def documents_readable_by(user)
        documents.joins(:authorizations)
                 .where(authorizations: { 
                   user: user, 
                   permission_level: ['read', 'write', 'admin'] 
                 })
                 .distinct
      end

      def documents_writable_by(user)
        documents.joins(:authorizations)
                 .where(authorizations: { 
                   user: user, 
                   permission_level: ['write', 'admin'] 
                 })
                 .distinct
      end

      # Document search within the entity
      def search_documents(query, category: nil)
        scope = documents
        scope = scope.where(document_category: category) if category.present?
        scope.where("title ILIKE ? OR description ILIKE ? OR content ILIKE ?", 
                   "%#{query}%", "%#{query}%", "%#{query}%")
      end

      # Document statistics
      def document_statistics
        {
          total_documents: documents.count,
          by_category: documents.group(:document_category).count,
          by_status: documents.group(:status).count,
          pending_validations: documents_requiring_validation.count,
          approved_documents: approved_documents.count,
          total_size: documents.joins(:file_attachment).sum('active_storage_blobs.byte_size')
        }
      end

      # Document workflow status
      def document_workflow_status
        {
          total: documents.count,
          draft: documents.where(status: 'draft').count,
          published: documents.where(status: 'published').count,
          under_review: documents_requiring_validation.count,
          approved: approved_documents.count,
          rejected: documents.joins(:validation_requests)
                            .where(validation_requests: { status: 'rejected' })
                            .distinct.count
        }
      end

      # Critical document tracking
      def missing_critical_documents
        critical_docs = required_document_types
        existing_categories = documents.pluck(:document_category).uniq
        critical_docs - existing_categories
      end

      def has_all_required_documents?
        missing_critical_documents.empty?
      end

      # Document compliance checking
      def document_compliance_status
        required_docs = required_document_types
        compliance = {}
        
        required_docs.each do |doc_type|
          docs = documents_by_category(doc_type)
          compliance[doc_type] = {
            required: true,
            present: docs.any?,
            approved: docs.joins(:validation_requests)
                         .where(validation_requests: { status: 'approved' })
                         .any?,
            count: docs.count
          }
        end
        
        compliance
      end

      private

      def default_document_space
        # Find or create a space for this ImmoPromo entity
        space_name = "#{self.class.name.demodulize} #{self.respond_to?(:name) ? self.name : self.id}"
        organization = self.respond_to?(:organization) ? self.organization : nil
        
        ::Space.find_or_create_by(
          name: space_name,
          organization: organization
        ) do |space|
          space.description = "Documents for #{space_name}"
          space.space_type = 'project'
        end
      end

      def default_document_folder
        space = default_document_space
        folder_name = self.class.name.demodulize.downcase
        
        ::Folder.find_or_create_by(
          name: folder_name,
          space: space
        ) do |folder|
          folder.description = "#{self.class.name.demodulize} documents"
        end
      end

      def required_document_types
        # Override in specific models to define required document types
        []
      end
    end
  end
end