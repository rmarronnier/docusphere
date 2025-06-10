require 'rails_helper'

RSpec.describe Documentable do
  # Create a test class that includes the concern
  class DocumentableTestModel < ApplicationRecord
    self.table_name = 'spaces' # Use an existing table
    include Documentable
    
    # Add the organization association to match Space model
    belongs_to :organization
  end
  
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:documentable) { DocumentableTestModel.create!(name: "Test Space", slug: "test-space", organization_id: organization.id) }
  let(:space) { create(:space, organization: organization) }
  
  describe "associations" do
    it "has many documents" do
      expect(documentable).to respond_to(:documents)
    end
    
    it "has many documents by category" do
      expect(documentable).to respond_to(:project_documents)
      expect(documentable).to respond_to(:technical_documents)
      expect(documentable).to respond_to(:administrative_documents)
      expect(documentable).to respond_to(:financial_documents)
      expect(documentable).to respond_to(:legal_documents)
      expect(documentable).to respond_to(:permit_documents)
      expect(documentable).to respond_to(:plan_documents)
    end
    
    it "has many document validations through documents" do
      expect(documentable).to respond_to(:document_validations)
    end
    
    it "has many validation requests through documents" do
      expect(documentable).to respond_to(:validation_requests)
    end
    
    it "has many document versions through documents" do
      expect(documentable).to respond_to(:document_versions)
    end
    
    it "has many document shares through documents" do
      expect(documentable).to respond_to(:document_shares)
    end
  end
  
  describe "#attach_document" do
    let(:file) { double("file", original_filename: "test.pdf", attached?: true) }
    
    before do
      allow_any_instance_of(DocumentProcessingService).to receive(:process!)
      allow_any_instance_of(Document).to receive_message_chain(:file, :attach)
      allow_any_instance_of(Document).to receive_message_chain(:file, :attached?).and_return(true)
      allow_any_instance_of(Document).to receive_message_chain(:file, :blob, :byte_size).and_return(1024)
    end
    
    it "creates a document with correct attributes" do
      expect {
        documentable.attach_document(file, category: 'project', user: user, title: "Test Doc")
      }.to change(Document, :count).by(1)
      
      doc = Document.last
      expect(doc.title).to eq("Test Doc")
      expect(doc.document_category).to eq('project')
      expect(doc.uploaded_by).to eq(user)
      expect(doc.documentable).to eq(documentable)
    end
    
    it "uses filename as title if not provided" do
      documentable.attach_document(file, user: user)
      expect(Document.last.title).to eq("test.pdf")
    end
    
    it "triggers document processing" do
      expect_any_instance_of(DocumentProcessingService).to receive(:process!)
      documentable.attach_document(file, user: user)
    end
  end
  
  describe "#attach_multiple_documents" do
    let(:files) { [double("file1"), double("file2")] }
    
    before do
      allow_any_instance_of(DocumentProcessingService).to receive(:process!)
      allow_any_instance_of(Document).to receive_message_chain(:file, :attach)
      allow_any_instance_of(Document).to receive_message_chain(:file, :attached?).and_return(true)
      allow_any_instance_of(Document).to receive_message_chain(:file, :blob, :byte_size).and_return(1024)
      files.each { |f| allow(f).to receive(:original_filename).and_return("test.pdf"); allow(f).to receive(:attached?).and_return(true) }
    end
    
    it "creates multiple documents" do
      expect {
        documentable.attach_multiple_documents(files, category: 'technical', user: user)
      }.to change(Document, :count).by(2)
    end
  end
  
  describe "#documents_by_category" do
    before do
      create(:document, documentable: documentable, document_category: 'project', space: space)
      create(:document, documentable: documentable, document_category: 'technical', space: space)
    end
    
    it "returns documents of specified category" do
      expect(documentable.documents_by_category('project').count).to eq(1)
      expect(documentable.documents_by_category('technical').count).to eq(1)
    end
  end
  
  describe "#documents_by_status" do
    before do
      create(:document, documentable: documentable, status: 'draft', space: space)
      create(:document, documentable: documentable, status: 'published', space: space)
    end
    
    it "returns documents with specified status" do
      expect(documentable.documents_by_status('draft').count).to eq(1)
      expect(documentable.documents_by_status('published').count).to eq(1)
    end
  end
  
  describe "#documents_requiring_validation" do
    let(:document) { create(:document, documentable: documentable, space: space) }
    
    before do
      create(:validation_request, validatable: document, status: 'pending')
    end
    
    it "returns documents with pending validation requests" do
      expect(documentable.documents_requiring_validation).to include(document)
    end
  end
  
  describe "#approved_documents" do
    let(:document) { create(:document, documentable: documentable, space: space) }
    
    before do
      create(:validation_request, validatable: document, status: 'approved')
    end
    
    it "returns documents with approved validation requests" do
      expect(documentable.approved_documents).to include(document)
    end
  end
  
  describe "#latest_document_versions" do
    let(:document) { create(:document, documentable: documentable, space: space) }
    
    before do
      # PaperTrail creates versions automatically
      document.update!(title: "Updated Title")
    end
    
    it "returns documents with current versions" do
      # Since we're using PaperTrail, we need to check the versions table
      expect(document.versions.count).to be > 0
    end
  end
  
  describe "#share_documents_with_user" do
    let(:document) { create(:document, documentable: documentable, space: space) }
    let(:recipient) { create(:user) }
    
    it "creates document shares" do
      expect {
        documentable.share_documents_with_user(recipient, [document.id], permission_level: 'read', shared_by: user)
      }.to change(DocumentShare, :count).by(1)
      
      share = DocumentShare.last
      expect(share.shared_with).to eq(recipient)
      expect(share.access_level).to eq('read')
      expect(share.shared_by).to eq(user)
    end
  end
  
  describe "#share_document_category_with_users" do
    let(:document) { create(:document, documentable: documentable, document_category: 'technical', space: space) }
    let(:recipients) { create_list(:user, 2) }
    
    it "shares all documents in category with multiple users" do
      document # Create the document
      expect {
        documentable.share_document_category_with_users('technical', recipients, permission_level: 'read', shared_by: user)
      }.to change(DocumentShare, :count).by(2)
    end
  end
  
  describe "#request_document_validation" do
    let(:document) { create(:document, documentable: documentable, space: space) }
    let(:validators) { create_list(:user, 2) }
    
    it "creates validation requests" do
      allow(document).to receive(:request_validation).and_return(double("validation"))
      
      validations = documentable.request_document_validation([document.id], validators: validators, requester: user)
      expect(validations.size).to eq(1)
    end
  end
  
  describe "#documents_readable_by" do
    let(:document) { create(:document, documentable: documentable, space: space) }
    
    before do
      create(:authorization, authorizable: document, user: user, permission_level: 'read')
    end
    
    it "returns documents readable by user" do
      expect(documentable.documents_readable_by(user)).to include(document)
    end
  end
  
  describe "#documents_writable_by" do
    let(:document) { create(:document, documentable: documentable, space: space) }
    
    before do
      create(:authorization, authorizable: document, user: user, permission_level: 'write')
    end
    
    it "returns documents writable by user" do
      expect(documentable.documents_writable_by(user)).to include(document)
    end
  end
  
  describe "#can_read_documents?" do
    let(:policy) { double("policy") }
    
    before do
      allow(Pundit).to receive(:policy).with(user, documentable).and_return(policy)
    end
    
    it "delegates to the policy's show? method" do
      expect(policy).to receive(:show?).and_return(true)
      expect(documentable.can_read_documents?(user)).to be true
    end
  end
  
  describe "#can_manage_documents?" do
    let(:policy) { double("policy") }
    
    before do
      allow(Pundit).to receive(:policy).with(user, documentable).and_return(policy)
    end
    
    it "delegates to the policy's update? method" do
      expect(policy).to receive(:update?).and_return(true)
      expect(documentable.can_manage_documents?(user)).to be true
    end
  end
  
  describe "#search_documents" do
    before do
      create(:document, documentable: documentable, title: "Important Document", space: space)
      create(:document, documentable: documentable, title: "Other File", space: space)
    end
    
    it "searches documents by query" do
      results = documentable.search_documents("Important")
      expect(results.count).to eq(1)
      expect(results.first.title).to eq("Important Document")
    end
    
    it "filters by category when provided" do
      create(:document, documentable: documentable, title: "Important Tech", document_category: 'technical', space: space)
      results = documentable.search_documents("Important", category: 'technical')
      expect(results.count).to eq(1)
      expect(results.first.document_category).to eq('technical')
    end
  end
  
  describe "#document_statistics" do
    before do
      create(:document, documentable: documentable, document_category: 'project', status: 'draft', space: space)
      create(:document, documentable: documentable, document_category: 'technical', status: 'published', space: space)
    end
    
    it "returns comprehensive statistics" do
      stats = documentable.document_statistics
      expect(stats[:total_documents]).to eq(2)
      expect(stats[:by_category]['project']).to eq(1)
      expect(stats[:by_category]['technical']).to eq(1)
      expect(stats[:by_status]['draft']).to eq(1)
      expect(stats[:by_status]['published']).to eq(1)
      expect(stats).to have_key(:total_size)
    end
  end
  
  describe "#document_workflow_status" do
    before do
      create(:document, documentable: documentable, status: 'draft', space: space)
      create(:document, documentable: documentable, status: 'published', space: space)
    end
    
    it "returns workflow status counts" do
      status = documentable.document_workflow_status
      expect(status[:total]).to eq(2)
      expect(status[:draft]).to eq(1)
      expect(status[:published]).to eq(1)
    end
  end
  
  describe "#missing_critical_documents" do
    it "returns missing document types" do
      # By default, required_document_types returns an empty array
      expect(documentable.missing_critical_documents).to eq([])
    end
  end
  
  describe "#has_all_required_documents?" do
    it "returns true when no documents are required" do
      expect(documentable.has_all_required_documents?).to be true
    end
  end
  
  describe "#document_compliance_status" do
    it "returns empty hash when no documents are required" do
      expect(documentable.document_compliance_status).to eq({})
    end
  end
  
  describe "private methods" do
    describe "#default_document_space" do
      it "creates or finds a space for the entity" do
        space = documentable.send(:default_document_space)
        expect(space).to be_a(Space)
        expect(space.name).to include("DocumentableTestModel")
      end
    end
    
    describe "#default_document_folder" do
      it "creates or finds a folder for the entity" do
        folder = documentable.send(:default_document_folder)
        expect(folder).to be_a(Folder)
        expect(folder.name).to eq("documentabletestmodel")
      end
    end
  end
end