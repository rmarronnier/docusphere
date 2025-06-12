require 'rails_helper'

RSpec.describe ClientsController, type: :controller do
  let(:organization) { create(:organization) }
  let(:commercial_user) { create(:user, organization: organization) }
  let(:direction_user) { create(:user, organization: organization) }
  let(:regular_user) { create(:user, organization: organization) }
  let(:client) { create(:client, created_by: commercial_user, organization: organization) }
  
  before do
    commercial_user.add_role(:commercial)
    direction_user.add_role(:direction)
  end
  
  describe 'GET #index' do
    context 'as commercial user' do
      before { sign_in commercial_user }
      
      it 'returns success' do
        get :index
        expect(response).to have_http_status(:success)
      end
      
      it 'filters clients by status' do
        active_client = create(:client, status: 'active', organization: organization)
        prospect_client = create(:client, status: 'prospect', organization: organization)
        
        get :index, params: { filter: 'active' }
        expect(assigns(:clients)).to include(active_client)
        expect(assigns(:clients)).not_to include(prospect_client)
      end
      
      it 'calculates client statistics' do
        get :index
        expect(assigns(:stats)).to include(
          :total, :active, :prospects, :new_this_month, :revenue_this_month
        )
      end
    end
    
    context 'as regular user' do
      before { sign_in regular_user }
      
      it 'redirects to root' do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Accès non autorisé')
      end
    end
  end
  
  describe 'GET #show' do
    before { sign_in commercial_user }
    
    it 'returns success' do
      get :show, params: { id: client.id }
      expect(response).to have_http_status(:success)
    end
    
    it 'loads client data' do
      get :show, params: { id: client.id }
      expect(assigns(:client)).to eq(client)
      expect(assigns(:recent_documents)).to be_present
      expect(assigns(:proposals)).to be_present
      expect(assigns(:contracts)).to be_present
    end
  end
  
  describe 'GET #new' do
    before { sign_in commercial_user }
    
    it 'returns success' do
      get :new
      expect(response).to have_http_status(:success)
    end
    
    it 'assigns a new client' do
      get :new
      expect(assigns(:client)).to be_a_new(Client)
    end
  end
  
  describe 'POST #create' do
    before { sign_in commercial_user }
    
    let(:valid_params) do
      {
        client: {
          name: 'ACME Corp',
          email: 'contact@acme.com',
          phone: '0123456789',
          address: '123 Main St',
          city: 'Paris',
          postal_code: '75001',
          country: 'France',
          client_type: 'company',
          status: 'prospect'
        }
      }
    end
    
    context 'with valid params' do
      it 'creates a new client' do
        expect {
          post :create, params: valid_params
        }.to change(Client, :count).by(1)
      end
      
      it 'sets created_by to current user' do
        post :create, params: valid_params
        expect(Client.last.created_by).to eq(commercial_user)
      end
      
      it 'creates initial folder for client' do
        expect_any_instance_of(ClientsController).to receive(:create_initial_folder)
        post :create, params: valid_params
      end
      
      it 'redirects to client' do
        post :create, params: valid_params
        expect(response).to redirect_to(Client.last)
        expect(flash[:notice]).to eq('Client créé avec succès')
      end
    end
    
    context 'with invalid params' do
      it 'does not create client' do
        expect {
          post :create, params: { client: { name: '' } }
        }.not_to change(Client, :count)
      end
      
      it 'renders new template' do
        post :create, params: { client: { name: '' } }
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
  
  describe 'PUT #update' do
    before { sign_in commercial_user }
    
    it 'updates client' do
      put :update, params: { id: client.id, client: { name: 'Updated Name' } }
      expect(client.reload.name).to eq('Updated Name')
    end
    
    it 'redirects to client' do
      put :update, params: { id: client.id, client: { name: 'Updated Name' } }
      expect(response).to redirect_to(client)
      expect(flash[:notice]).to eq('Client mis à jour avec succès')
    end
  end
  
  describe 'DELETE #destroy' do
    before { sign_in commercial_user }
    
    it 'destroys client' do
      client # create it
      expect {
        delete :destroy, params: { id: client.id }
      }.to change(Client, :count).by(-1)
    end
    
    it 'redirects to index' do
      delete :destroy, params: { id: client.id }
      expect(response).to redirect_to(clients_path)
      expect(flash[:notice]).to eq('Client supprimé')
    end
  end
  
  describe 'GET #documents' do
    before { sign_in commercial_user }
    
    it 'returns client documents' do
      document = create(:document, documentable: client)
      get :documents, params: { id: client.id }
      expect(assigns(:documents)).to include(document)
    end
    
    it 'responds to json' do
      get :documents, params: { id: client.id }, format: :json
      expect(response.content_type).to include('application/json')
    end
  end
  
  describe 'GET #history' do
    before { sign_in commercial_user }
    
    it 'returns client activity history' do
      get :history, params: { id: client.id }
      expect(response).to have_http_status(:success)
      expect(assigns(:activities)).to be_present
      expect(assigns(:timeline_data)).to be_present
    end
  end
  
  describe 'POST #import' do
    before { sign_in commercial_user }
    
    context 'with valid file' do
      let(:file) { fixture_file_upload('clients.csv', 'text/csv') }
      
      it 'imports clients' do
        allow_any_instance_of(ClientImportService).to receive(:import)
          .and_return({ success: true, imported: 5 })
        
        post :import, params: { file: file }
        expect(response).to redirect_to(clients_path)
        expect(flash[:notice]).to eq('5 clients importés avec succès')
      end
    end
    
    context 'without file' do
      it 'shows error' do
        post :import
        expect(response).to redirect_to(clients_path)
        expect(flash[:alert]).to eq('Veuillez sélectionner un fichier')
      end
    end
  end
  
  describe 'GET #export' do
    before { sign_in commercial_user }
    
    it 'exports as CSV' do
      get :export, format: :csv
      expect(response.content_type).to eq('text/csv')
      expect(response.headers['Content-Disposition']).to include('clients_')
    end
    
    it 'exports as Excel' do
      allow_any_instance_of(ClientsController).to receive(:generate_excel).and_return('Excel data')
      get :export, format: :xlsx
      expect(response.content_type).to eq('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
    end
  end
  
  describe 'authorization' do
    it 'allows commercial users' do
      sign_in commercial_user
      get :index
      expect(response).to have_http_status(:success)
    end
    
    it 'allows direction users' do
      sign_in direction_user
      get :index
      expect(response).to have_http_status(:success)
    end
    
    it 'denies regular users' do
      sign_in regular_user
      get :index
      expect(response).to redirect_to(root_path)
    end
  end
end