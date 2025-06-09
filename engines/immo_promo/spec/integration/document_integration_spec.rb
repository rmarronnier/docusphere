require 'rails_helper'

RSpec.describe "Document Integration in ImmoPromo", type: :integration do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :admin, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization, project_manager: user) }
  let(:permit) { create(:immo_promo_permit, project: project) }
  let(:task) { create(:immo_promo_task, phase: project.phases.first) }
  let(:stakeholder) { create(:immo_promo_stakeholder, project: project) }
  
  describe "Documentable concern integration" do
    context "with Project" do
      it "has document associations" do
        expect(project).to respond_to(:documents)
        expect(project).to respond_to(:project_documents)
        expect(project).to respond_to(:technical_documents)
        expect(project).to respond_to(:administrative_documents)
        expect(project).to respond_to(:financial_documents)
        expect(project).to respond_to(:legal_documents)
        expect(project).to respond_to(:permit_documents)
        expect(project).to respond_to(:plan_documents)
      end
      
      it "can attach documents" do
        file = fixture_file_upload('spec/fixtures/test_document.pdf', 'application/pdf')
        
        document = project.attach_document(
          file,
          category: 'project',
          user: user,
          title: 'Cahier des charges',
          description: 'Document principal du projet'
        )
        
        expect(document).to be_persisted
        expect(document.document_category).to eq('project')
        expect(document.uploaded_by).to eq(user)
        expect(document.documentable).to eq(project)
        expect(document.file).to be_attached
      end
      
      it "can filter documents by category" do
        # Create documents of different categories
        categories = %w[project technical administrative financial legal]
        documents = categories.map do |category|
          file = fixture_file_upload('spec/fixtures/test_document.pdf', 'application/pdf')
          project.attach_document(file, category: category, user: user)
        end
        
        expect(project.documents_by_category('project').count).to eq(1)
        expect(project.documents_by_category('technical').count).to eq(1)
        expect(project.documents.count).to eq(5)
      end
    end
    
    context "with Permit" do
      it "has document associations" do
        expect(permit).to respond_to(:documents)
        expect(permit).to respond_to(:permit_documents)
      end
      
      it "can attach permit-specific documents" do
        file = fixture_file_upload('spec/fixtures/test_document.pdf', 'application/pdf')
        
        document = permit.attach_document(
          file,
          category: 'permit',
          user: user,
          title: 'Permis de construire',
          description: 'Document officiel du permis'
        )
        
        expect(document.document_category).to eq('permit')
        expect(document.documentable).to eq(permit)
      end
    end
    
    context "with Task" do
      it "can attach task-related documents" do
        file = fixture_file_upload('spec/fixtures/test_document.pdf', 'application/pdf')
        
        document = task.attach_document(
          file,
          category: 'technical',
          user: user,
          title: 'Rapport technique',
          description: 'Rapport d\'avancement de la tâche'
        )
        
        expect(document.documentable).to eq(task)
        expect(task.documents.count).to eq(1)
      end
    end
    
    context "with Stakeholder" do
      it "can attach stakeholder documents" do
        file = fixture_file_upload('spec/fixtures/test_document.pdf', 'application/pdf')
        
        document = stakeholder.attach_document(
          file,
          category: 'contract',
          user: user,
          title: 'Contrat intervenant',
          description: 'Contrat avec l\'entreprise'
        )
        
        expect(document.documentable).to eq(stakeholder)
        expect(document.document_category).to eq('contract')
      end
    end
  end
  
  describe "Document workflow integration" do
    let!(:document) do
      file = fixture_file_upload('spec/fixtures/test_document.pdf', 'application/pdf')
      project.attach_document(file, category: 'financial', user: user, title: 'Budget prévisionnel')
    end
    
    it "can request validation for documents" do
      validators = create_list(:user, 2, organization: organization)
      
      validation_requests = project.request_document_validation(
        [document.id],
        validators: validators,
        requester: user,
        min_validations: 2
      )
      
      expect(validation_requests).not_to be_empty
      expect(document.validation_requests.count).to eq(1)
      expect(document.validation_requests.first.validators).to match_array(validators)
    end
    
    it "can share documents with stakeholders" do
      shares = project.share_documents_with_stakeholder(
        stakeholder,
        [document.id],
        permission_level: 'read',
        user: user
      )
      
      expect(shares).not_to be_empty
      expect(document.document_shares.count).to eq(1)
      share = document.document_shares.first
      expect(share.shared_with_email).to eq(stakeholder.email)
      expect(share.permission_level).to eq('read')
    end
    
    it "tracks document statistics" do
      # Add more documents
      3.times do
        file = fixture_file_upload('spec/fixtures/test_document.pdf', 'application/pdf')
        project.attach_document(file, category: 'technical', user: user)
      end
      
      stats = project.document_statistics
      
      expect(stats[:total_documents]).to eq(4)
      expect(stats[:by_category]['financial']).to eq(1)
      expect(stats[:by_category]['technical']).to eq(3)
      expect(stats[:total_size]).to be > 0
    end
    
    it "tracks document compliance" do
      compliance = project.document_compliance_status
      
      # Project should require certain document types
      expect(compliance).to be_a(Hash)
      expect(compliance.keys).to include('project', 'technical', 'administrative', 'financial', 'legal')
      
      # Check financial documents compliance
      expect(compliance['financial'][:required]).to be true
      expect(compliance['financial'][:present]).to be true
      expect(compliance['financial'][:count]).to eq(1)
    end
  end
  
  describe "Document AI processing integration" do
    let!(:document) do
      file = fixture_file_upload('spec/fixtures/test_document.pdf', 'application/pdf')
      project.attach_document(file, category: 'permit', user: user, title: 'Permis de construire')
    end
    
    it "triggers document processing jobs" do
      expect(DocumentProcessingJob).to have_been_enqueued.with(document.id)
    end
    
    it "extracts metadata and content" do
      # Simulate AI processing results
      document.update!(
        content: "Permis de construire pour la construction d'un immeuble résidentiel",
        extracted_entities: {
          dates: ["2024-01-15", "2024-12-31"],
          amounts: ["250000", "1500000"],
          organizations: ["Mairie de Paris", "Bureau d'études ABC"]
        },
        ai_classification: "permit",
        ai_confidence: 0.95
      )
      
      expect(document.extracted_entities).not_to be_empty
      expect(document.ai_classification).to eq('permit')
      expect(document.ai_confidence).to be > 0.9
    end
  end
  
  describe "Document permissions" do
    let(:other_user) { create(:user, organization: organization) }
    let!(:document) do
      file = fixture_file_upload('spec/fixtures/test_document.pdf', 'application/pdf')
      project.attach_document(file, category: 'legal', user: user)
    end
    
    it "respects document access permissions" do
      # Document owner can access
      expect(document.uploaded_by).to eq(user)
      
      # Other users need explicit permissions
      readable_docs = project.documents_readable_by(other_user)
      expect(readable_docs).to be_empty
      
      # Grant read permission
      Authorization.create!(
        authorizable: document,
        user: other_user,
        permission_level: 'read'
      )
      
      readable_docs = project.documents_readable_by(other_user)
      expect(readable_docs).to include(document)
    end
    
    it "project manager can access all project documents" do
      # Project manager has implicit access
      readable_docs = project.documents_readable_by(project.project_manager)
      expect(readable_docs).to include(document)
    end
  end
  
  describe "Document organization" do
    it "creates default document space for project" do
      space = project.send(:default_document_space)
      
      expect(space).to be_persisted
      expect(space.name).to include("Project #{project.name}")
      expect(space.organization).to eq(organization)
      expect(space.space_type).to eq('project')
    end
    
    it "creates default folder structure" do
      folder = project.send(:default_document_folder)
      
      expect(folder).to be_persisted
      expect(folder.name).to eq('project')
      expect(folder.space).to eq(project.send(:default_document_space))
    end
  end
end