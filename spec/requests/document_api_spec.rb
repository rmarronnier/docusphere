require 'rails_helper'

RSpec.describe "Document API", type: :request do
  let(:user) { create(:user) }
  let(:organization) { user.organization }
  let(:space) { create(:space, organization: organization) }
  let(:valid_headers) {
    {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
  }
  
  before do
    sign_in user
  end
  
  describe "POST /ged/documents (AJAX upload)" do
    let(:valid_params) do
      {
        document: {
          title: "API Test Document",
          description: "Uploaded via API",
          space_id: space.id,
          file: fixture_file_upload('test_document.pdf', 'application/pdf')
        }
      }
    end
    
    context "with valid parameters" do
      it "creates a document and returns success" do
        expect {
          post ged_upload_document_path, params: valid_params, headers: valid_headers
        }.to change(Document, :count).by(1)
        
        expect(response).to have_http_status(:ok)
        
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['redirect_url']).to match(/\/ged\/documents\/\d+/)
        
        # Vérifier que le document a été créé correctement
        document = Document.last
        expect(document.title).to eq("API Test Document")
        expect(document.processing_status).to eq("pending")
      end
      
      it "enqueues processing jobs" do
        expect {
          post ged_upload_document_path, params: valid_params, headers: valid_headers
        }.to have_enqueued_job(DocumentProcessingJob)
      end
    end
    
    context "with invalid parameters" do
      let(:invalid_params) do
        {
          document: {
            title: "", # titre vide
            space_id: space.id
          }
        }
      end
      
      it "returns error response" do
        expect {
          post ged_upload_document_path, params: invalid_params, headers: valid_headers
        }.not_to change(Document, :count)
        
        expect(response).to have_http_status(:unprocessable_entity)
        
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['errors']).to include("Le titre doit être rempli")
        expect(json['errors']).to include("Le fichier doit être rempli")
      end
    end
    
    context "with file size validation" do
      it "rejects files larger than limit" do
        # Créer un gros fichier temporaire
        large_file = Tempfile.new(['large', '.pdf'])
        large_file.write("x" * 101.megabytes)
        large_file.rewind
        
        params = {
          document: {
            title: "Large File",
            space_id: space.id,
            file: Rack::Test::UploadedFile.new(large_file.path, 'application/pdf')
          }
        }
        
        post ged_upload_document_path, params: params, headers: valid_headers
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to include(match(/taille du fichier/i))
        
        large_file.close
        large_file.unlink
      end
    end
  end
  
  describe "GET /ged/documents/:id/status (Polling status)" do
    let(:document) { create(:document, space: space, user: user, processing_status: 'processing') }
    
    it "returns current processing status" do
      get ged_document_status_path(document), headers: valid_headers
      
      expect(response).to have_http_status(:ok)
      
      json = JSON.parse(response.body)
      expect(json['status']).to eq('processing')
      expect(json['processing_status']).to eq('processing')
      expect(json).to have_key('virus_scan_status')
    end
    
    it "includes completion percentage" do
      document.update!(
        processing_status: 'completed',
        ocr_performed: true,
        virus_scan_status: 'clean'
      )
      
      get ged_document_status_path(document), headers: valid_headers
      
      json = JSON.parse(response.body)
      expect(json['status']).to eq('completed')
      expect(json['completion_percentage']).to eq(100)
    end
  end
  
  describe "DELETE /ged/documents/:id" do
    let!(:document) { create(:document, space: space, user: user) }
    
    context "as document owner" do
      it "deletes the document" do
        expect {
          delete ged_document_path(document), headers: valid_headers
        }.to change(Document, :count).by(-1)
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
      end
    end
    
    context "as non-owner" do
      let(:other_user) { create(:user, organization: organization) }
      
      before { sign_in other_user }
      
      it "denies access" do
        expect {
          delete ged_document_path(document), headers: valid_headers
        }.not_to change(Document, :count)
        
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end