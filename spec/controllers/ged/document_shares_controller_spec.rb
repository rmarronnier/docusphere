# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ged::DocumentSharesController, type: :controller do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:other_user) { create(:user, organization: organization) }
  let(:document) { create(:document, uploaded_by: user, organization: organization) }
  
  before do
    sign_in user
  end
  
  describe 'POST #create' do
    context 'with valid params' do
      let(:valid_params) do
        {
          document_id: document.id,
          email: other_user.email,
          permission: 'read',
          message: 'Please review this document'
        }
      end
      
      it 'creates a new document share' do
        expect {
          post :create, params: valid_params, format: :json
        }.to change(DocumentShare, :count).by(1)
      end
      
      it 'returns success response' do
        post :create, params: valid_params, format: :json
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['message']).to eq('Document partagé avec succès')
        expect(json_response['share']['user_name']).to eq(other_user.display_name)
      end
      
      it 'sends notification' do
        notification_service = instance_double(NotificationService)
        allow(NotificationService).to receive(:new).and_return(notification_service)
        expect(notification_service).to receive(:notify_document_shared).with(
          document: document,
          recipient: other_user,
          sender: user,
          message: 'Please review this document'
        )
        
        post :create, params: valid_params, format: :json
      end
      
      it 'updates existing share if already shared' do
        existing_share = create(:document_share, document: document, shared_with: other_user, access_level: 'read')
        
        expect {
          post :create, params: valid_params.merge(permission: 'write'), format: :json
        }.not_to change(DocumentShare, :count)
        
        existing_share.reload
        expect(existing_share.access_level).to eq('write')
      end
    end
    
    context 'with invalid params' do
      it 'returns error when user does not exist' do
        post :create, params: {
          document_id: document.id,
          email: 'nonexistent@example.com',
          permission: 'read'
        }, format: :json
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include("L'utilisateur avec cet email n'existe pas")
      end
      
      it 'returns error when sharing with self' do
        post :create, params: {
          document_id: document.id,
          email: user.email,
          permission: 'read'
        }, format: :json
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('Vous ne pouvez pas partager un document avec vous-même')
      end
    end
    
    context 'authorization' do
      it 'requires share permission' do
        allow_any_instance_of(DocumentPolicy).to receive(:share?).and_return(false)
        
        post :create, params: {
          document_id: document.id,
          email: other_user.email,
          permission: 'read'
        }, format: :json
        
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
  
  describe 'DELETE #destroy' do
    let!(:document_share) { create(:document_share, document: document, shared_with: other_user, shared_by: user) }
    
    it 'destroys the document share' do
      expect {
        delete :destroy, params: { document_id: document.id, id: document_share.id }, format: :json
      }.to change(DocumentShare, :count).by(-1)
    end
    
    it 'returns no content' do
      delete :destroy, params: { document_id: document.id, id: document_share.id }, format: :json
      expect(response).to have_http_status(:no_content)
    end
    
    it 'requires share permission' do
      allow_any_instance_of(DocumentPolicy).to receive(:share?).and_return(false)
      
      delete :destroy, params: { document_id: document.id, id: document_share.id }, format: :json
      
      expect(response).to have_http_status(:forbidden)
    end
  end
end