# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Ged::DocumentOperations', type: :controller do
  controller(ApplicationController) do
    include Ged::DocumentOperations
  end

  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:space) { create(:space, organization: organization) }
  let(:document) { create(:document, :with_pdf_file, space: space, uploaded_by: user) }

  before do
    sign_in user
    routes.draw do
      get 'download_document/:id' => 'anonymous#download_document'
      get 'preview_document/:id' => 'anonymous#preview_document'
      get 'document_status/:id' => 'anonymous#document_status'
      post 'upload_document' => 'anonymous#upload_document'
    end
  end

  describe '#download_document' do
    it 'sends file with attachment disposition' do
      get :download_document, params: { id: document.id }
      
      expect(response).to have_http_status(:success)
      expect(response.headers['Content-Disposition']).to include('attachment')
      expect(response.headers['Content-Disposition']).to include(document.file.filename.to_s)
      expect(response.content_type).to eq(document.file.content_type)
    end
    
    it 'increments download count' do
      expect {
        get :download_document, params: { id: document.id }
      }.to change { document.reload.download_count }.by(1)
    end
    
    context 'when document has no file' do
      let(:document) { create(:document, space: space, uploaded_by: user) }
      
      it 'redirects with alert' do
        get :download_document, params: { id: document.id }
        
        expect(response).to redirect_to(ged_document_path(document))
        expect(flash[:alert]).to eq("Aucun fichier attaché à ce document")
      end
    end
    
    context 'when user lacks permission' do
      let(:other_org) { create(:organization) }
      let(:other_document) { create(:document, organization: other_org) }
      
      it 'raises not found error' do
        expect {
          get :download_document, params: { id: other_document.id }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#preview_document' do
    context 'with previewable document' do
      it 'redirects to blob URL with inline disposition' do
        get :preview_document, params: { id: document.id }
        
        expect(response).to redirect_to(rails_blob_url(document.file, disposition: 'inline'))
      end
      
      it 'increments view count' do
        expect {
          get :preview_document, params: { id: document.id }
        }.to change { document.reload.view_count }.by(1)
      end
    end
    
    context 'with non-previewable document' do
      let(:document) { create(:document, :with_pdf_file, space: space, uploaded_by: user) }
      
      before do
        allow_any_instance_of(Document).to receive(:previewable?).and_return(false)
      end
      
      it 'returns error JSON' do
        get :preview_document, params: { id: document.id }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('Ce type de document ne peut pas être prévisualisé')
      end
    end
  end

  describe '#document_status' do
    it 'returns document status information' do
      get :document_status, params: { id: document.id }
      
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      
      expect(json_response).to include(
        'status' => document.status,
        'processing_status' => document.processing_status,
        'virus_scan_status' => document.virus_scan_status,
        'locked' => document.locked?,
        'view_count' => document.view_count,
        'download_count' => document.download_count
      )
    end
  end

  describe '#upload_document' do
    let(:file) { fixture_file_upload('spec/fixtures/files/sample.pdf', 'application/pdf') }
    let(:folder) { create(:folder, space: space) }
    
    context 'with valid params' do
      let(:valid_params) do
        {
          document: {
            title: 'Test Document',
            description: 'Test description',
            file: file,
            space_id: space.id,
            folder_id: folder.id,
            tags: 'important, test',
            category: 'report'
          }
        }
      end
      
      it 'creates a new document' do
        expect {
          post :upload_document, params: valid_params, format: :json
        }.to change(Document, :count).by(1)
      end
      
      it 'returns success response' do
        post :upload_document, params: valid_params, format: :json
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['message']).to eq('Document téléversé avec succès')
      end
      
      it 'assigns tags' do
        post :upload_document, params: valid_params, format: :json
        
        document = Document.last
        expect(document.tag_list).to include('important', 'test')
      end
      
      it 'sets document type from category' do
        post :upload_document, params: valid_params, format: :json
        
        document = Document.last
        expect(document.document_type).to eq('report')
      end
      
      it 'triggers background jobs' do
        expect(DocumentProcessingJob).to receive(:perform_later)
        expect(VirusScanJob).to receive(:perform_later)
        
        post :upload_document, params: valid_params, format: :json
      end
    end
    
    context 'with duplicate document' do
      let!(:existing_document) { create(:document, title: 'Test Document', folder: folder) }
      
      let(:duplicate_params) do
        {
          document: {
            title: 'Test Document',
            file: file,
            folder_id: folder.id
          }
        }
      end
      
      it 'returns duplicate detected response' do
        post :upload_document, params: duplicate_params, format: :json
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['duplicate_detected']).to be true
        expect(json_response['existing_document']['id']).to eq(existing_document.id)
      end
    end
    
    context 'with invalid file type' do
      let(:invalid_file) do
        # Create a file with dangerous extension
        temp_file = Tempfile.new(['malicious', '.exe'])
        temp_file.write('fake executable content')
        temp_file.rewind
        Rack::Test::UploadedFile.new(temp_file.path, 'application/x-msdownload')
      end
      
      let(:invalid_params) do
        {
          document: {
            title: 'Malicious File',
            file: invalid_file,
            space_id: space.id
          }
        }
      end
      
      it 'rejects dangerous file types' do
        post :upload_document, params: invalid_params, format: :json
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['errors']).to include(match(/Type de fichier non autorisé/))
      end
    end
  end
end