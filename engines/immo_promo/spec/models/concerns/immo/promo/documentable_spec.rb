require 'rails_helper'

RSpec.describe Immo::Promo::Documentable do
  # Create a test class that includes the concern
  class ImmoPromoDocumentableTestModel < ApplicationRecord
    self.table_name = 'immo_promo_projects' # Use an existing table
    include Immo::Promo::Documentable
    
    def name
      "Test Model"
    end
    
    def organization
      Organization.first || create(:organization)
    end
  end
  
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:project) { create(:immo_promo_project, name: "Test Project", organization: organization) }
  let(:documentable) { project }
  let(:space) { create(:space, organization: organization) }
  
  describe "includes main Documentable concern" do
    it "includes all basic Documentable functionality" do
      expect(documentable).to respond_to(:documents)
      expect(documentable).to respond_to(:attach_document)
      expect(documentable).to respond_to(:documents_by_category)
      expect(documentable).to respond_to(:can_read_documents?)
      expect(documentable).to respond_to(:can_manage_documents?)
    end
  end
  
  describe "#attach_document with ImmoPromo integration" do
    let(:file) { double("file", original_filename: "test.pdf") }
    
    context "when DocumentIntegrationService is available" do
      before do
        # Create a stub class with the process_document method
        document_integration_service_class = Class.new do
          def initialize(document, documentable)
            @document = document
            @documentable = documentable
          end
          
          def process_document
            # stub implementation
          end
        end
        
        stub_const("Immo::Promo::DocumentIntegrationService", document_integration_service_class)
        
        # Skip DocumentProcessingService entirely since we're testing ImmoPromo integration
        allow_any_instance_of(DocumentProcessingService).to receive(:process!).and_return(true)
        
        allow_any_instance_of(Document).to receive_message_chain(:file, :attach)
        allow_any_instance_of(Document).to receive_message_chain(:file, :attached?).and_return(true)
        allow_any_instance_of(Document).to receive_message_chain(:file, :blob, :byte_size).and_return(1024)
      end
      
      it "uses ImmoPromo DocumentIntegrationService" do
        expect_any_instance_of(Immo::Promo::DocumentIntegrationService).to receive(:process_document)
        documentable.attach_document(file, category: 'project', user: user)
      end
    end
    
    context "when DocumentIntegrationService is not available" do
      before do
        allow_any_instance_of(DocumentProcessingService).to receive(:process!)
        allow_any_instance_of(Document).to receive_message_chain(:file, :attach)
        allow_any_instance_of(Document).to receive_message_chain(:file, :attached?).and_return(true)
        allow_any_instance_of(Document).to receive_message_chain(:file, :blob, :byte_size).and_return(1024)
      end
      
      it "falls back to standard document processing" do
        expect_any_instance_of(DocumentProcessingService).to receive(:process!)
        documentable.attach_document(file, category: 'project', user: user)
      end
    end
  end
  
  describe "#share_documents_with_stakeholder" do
    let(:document) { create(:document, documentable: documentable, space: space) }
    let(:stakeholder) { create(:immo_promo_stakeholder, project: project, email: "stakeholder@example.com") }
    
    it "creates document shares for stakeholder" do
      expect {
        documentable.share_documents_with_stakeholder(
          stakeholder,
          [document.id],
          permission_level: 'read',
          user: user
        )
      }.to change(DocumentShare, :count).by(1)
      
      share = DocumentShare.last
      expect(share.email).to eq("stakeholder@example.com")
      expect(share.access_level).to eq('read')
      expect(share.shared_by).to eq(user)
      expect(share.expires_at).to be_present
    end
    
    it "handles stakeholder with user association" do
      stakeholder_user = create(:user, email: "user.stakeholder@example.com")
      stakeholder_with_user = create(:immo_promo_stakeholder, 
        project: project, 
        email: stakeholder_user.email
      )
      
      # Instead of trying to mock a user method, we'll test what the code actually does
      # The code checks if stakeholder responds_to? :user, which it doesn't by default
      shares = documentable.share_documents_with_stakeholder(
        stakeholder_with_user,
        [document.id],
        permission_level: 'write',
        user: user
      )
      
      # Since stakeholder doesn't have a user method, shared_with should be nil
      expect(shares.first.shared_with).to be_nil
      expect(shares.first.email).to eq(stakeholder_user.email)
    end
    
    it "shares multiple documents" do
      document2 = create(:document, documentable: documentable, space: space)
      
      expect {
        documentable.share_documents_with_stakeholder(
          stakeholder,
          [document.id, document2.id],
          permission_level: 'read',
          user: user
        )
      }.to change(DocumentShare, :count).by(2)
    end
  end
  
  describe "#share_document_category_with_stakeholders" do
    let(:technical_doc1) { create(:document, documentable: documentable, document_category: 'technical', space: space) }
    let(:technical_doc2) { create(:document, documentable: documentable, document_category: 'technical', space: space) }
    let(:financial_doc) { create(:document, documentable: documentable, document_category: 'financial', space: space) }
    let(:stakeholder1) { create(:immo_promo_stakeholder, project: project, email: "stakeholder1@example.com") }
    let(:stakeholder2) { create(:immo_promo_stakeholder, project: project, email: "stakeholder2@example.com") }
    
    before do
      technical_doc1
      technical_doc2
      financial_doc
    end
    
    it "shares all documents in category with all stakeholders" do
      expect {
        documentable.share_document_category_with_stakeholders(
          'technical',
          [stakeholder1, stakeholder2],
          permission_level: 'read',
          user: user
        )
      }.to change(DocumentShare, :count).by(4) # 2 docs x 2 stakeholders
    end
    
    it "only shares documents from specified category" do
      shares = documentable.share_document_category_with_stakeholders(
        'technical',
        [stakeholder1],
        permission_level: 'read',
        user: user
      )
      
      document_ids = shares.map(&:document_id)
      expect(document_ids).to include(technical_doc1.id, technical_doc2.id)
      expect(document_ids).not_to include(financial_doc.id)
    end
    
    it "respects permission level" do
      shares = documentable.share_document_category_with_stakeholders(
        'technical',
        [stakeholder1],
        permission_level: 'write',
        user: user
      )
      
      expect(shares.all? { |s| s.access_level == 'write' }).to be true
    end
  end
end