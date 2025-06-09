require 'rails_helper'

RSpec.describe Immo::Promo::DocumentsController, type: :controller do
  routes { ImmoPromo::Engine.routes }
  
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :admin, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization, project_manager: user) }
  let(:document) { create(:document, documentable: project, uploaded_by: user) }
  
  before do
    sign_in user
  end
  
  describe "GET #index" do
    it "returns a success response" do
      get :index, params: { project_id: project.id }
      expect(response).to be_successful
    end
    
    it "assigns documents" do
      document # Create the document
      get :index, params: { project_id: project.id }
      expect(assigns(:documents)).to include(document)
    end
    
    it "filters by category" do
      financial_doc = create(:document, documentable: project, document_category: 'financial')
      technical_doc = create(:document, documentable: project, document_category: 'technical')
      
      get :index, params: { project_id: project.id, category: 'financial' }
      
      expect(assigns(:documents)).to include(financial_doc)
      expect(assigns(:documents)).not_to include(technical_doc)
    end
    
    it "calculates statistics" do
      create_list(:document, 3, documentable: project)
      get :index, params: { project_id: project.id }
      
      stats = assigns(:statistics)
      expect(stats[:total_documents]).to eq(3)
    end
  end
  
  describe "GET #show" do
    it "returns a success response" do
      get :show, params: { project_id: project.id, id: document.id }
      expect(response).to be_successful
    end
    
    it "assigns the document" do
      get :show, params: { project_id: project.id, id: document.id }
      expect(assigns(:document)).to eq(document)
    end
  end
  
  describe "GET #new" do
    it "returns a success response" do
      get :new, params: { project_id: project.id }
      expect(response).to be_successful
    end
    
    it "assigns categories based on documentable type" do
      get :new, params: { project_id: project.id }
      categories = assigns(:categories)
      
      expect(categories).to include('project', 'technical', 'financial', 'permit')
    end
  end
  
  describe "POST #create" do
    let(:file) { fixture_file_upload('spec/fixtures/test_document.pdf', 'application/pdf') }
    
    context "with valid params" do
      it "creates new documents" do
        expect {
          post :create, params: {
            project_id: project.id,
            documents: {
              files: [file],
              category: 'technical',
              title: 'Test Document',
              description: 'Test description'
            }
          }
        }.to change(Document, :count).by(1)
      end
      
      it "redirects to documents index" do
        post :create, params: {
          project_id: project.id,
          documents: {
            files: [file],
            category: 'technical'
          }
        }
        
        expect(response).to redirect_to(project_documents_path(project))
      end
      
      it "attaches files to documents" do
        post :create, params: {
          project_id: project.id,
          documents: {
            files: [file],
            category: 'technical'
          }
        }
        
        document = Document.last
        expect(document.file).to be_attached
      end
    end
    
    context "without files" do
      it "redirects with alert" do
        post :create, params: {
          project_id: project.id,
          documents: {
            files: [],
            category: 'technical'
          }
        }
        
        expect(response).to redirect_to(new_project_document_path(project))
        expect(flash[:alert]).to be_present
      end
    end
  end
  
  describe "GET #edit" do
    it "returns a success response" do
      get :edit, params: { project_id: project.id, id: document.id }
      expect(response).to be_successful
    end
  end
  
  describe "PATCH #update" do
    context "with valid params" do
      it "updates the document" do
        patch :update, params: {
          project_id: project.id,
          id: document.id,
          document: {
            title: 'Updated Title',
            description: 'Updated description'
          }
        }
        
        document.reload
        expect(document.title).to eq('Updated Title')
      end
      
      it "redirects to document" do
        patch :update, params: {
          project_id: project.id,
          id: document.id,
          document: { title: 'Updated' }
        }
        
        expect(response).to redirect_to(project_document_path(project, document))
      end
    end
  end
  
  describe "DELETE #destroy" do
    it "destroys the document" do
      document # Create the document
      
      expect {
        delete :destroy, params: { project_id: project.id, id: document.id }
      }.to change(Document, :count).by(-1)
    end
    
    it "redirects to documents index" do
      delete :destroy, params: { project_id: project.id, id: document.id }
      expect(response).to redirect_to(project_documents_path(project))
    end
  end
  
  describe "GET #download" do
    it "redirects to blob download" do
      get :download, params: { project_id: project.id, id: document.id }
      expect(response).to be_redirect
    end
  end
  
  describe "GET #preview" do
    context "with preview URL" do
      before do
        allow(document).to receive(:preview_url).and_return('http://preview.url')
      end
      
      it "redirects to preview URL" do
        get :preview, params: { project_id: project.id, id: document.id }
        expect(response).to redirect_to('http://preview.url')
      end
    end
  end
  
  describe "POST #share" do
    let(:stakeholder) { create(:immo_promo_stakeholder, project: project) }
    
    it "creates document shares" do
      expect {
        post :share, params: {
          project_id: project.id,
          id: document.id,
          stakeholder_ids: [stakeholder.id],
          permission_level: 'read'
        }
      }.to change(DocumentShare, :count)
    end
    
    it "redirects to document" do
      post :share, params: {
        project_id: project.id,
        id: document.id,
        stakeholder_ids: [stakeholder.id]
      }
      
      expect(response).to redirect_to(project_document_path(project, document))
    end
  end
  
  describe "POST #request_validation" do
    let(:validator) { create(:user, organization: organization) }
    
    it "creates validation request" do
      expect {
        post :request_validation, params: {
          project_id: project.id,
          id: document.id,
          validator_ids: [validator.id],
          min_validations: 1
        }
      }.to change(ValidationRequest, :count)
    end
  end
  
  describe "authorization" do
    let(:other_user) { create(:user, organization: organization) }
    let(:other_project) { create(:immo_promo_project, organization: create(:organization)) }
    
    before do
      sign_in other_user
    end
    
    it "prevents access to projects from other organizations" do
      get :index, params: { project_id: other_project.id }
      expect(response).to have_http_status(:forbidden)
    end
    
    it "allows project team members to access documents" do
      project.stakeholders.create!(
        name: other_user.name,
        email: other_user.email,
        stakeholder_type: 'architect',
        user: other_user
      )
      
      get :index, params: { project_id: project.id }
      expect(response).to be_successful
    end
  end
  
  describe "bulk actions" do
    let(:documents) { create_list(:document, 3, documentable: project) }
    
    describe "POST #bulk_actions" do
      it "deletes multiple documents" do
        document_ids = documents.map(&:id)
        
        expect {
          post :bulk_actions, params: {
            project_id: project.id,
            document_ids: document_ids,
            bulk_action: 'delete'
          }
        }.to change(Document, :count).by(-3)
      end
      
      it "handles share action" do
        post :bulk_actions, params: {
          project_id: project.id,
          document_ids: documents.map(&:id),
          bulk_action: 'share'
        }
        
        expect(session[:bulk_document_ids]).to eq(documents.map(&:id).map(&:to_s))
      end
    end
  end
end