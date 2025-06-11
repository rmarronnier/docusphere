require 'rails_helper'

RSpec.describe GedController, type: :controller do
  let(:user) { create(:user, organization: organization) }
  let(:organization) { create(:organization) }
  let(:space) { create(:space, organization: organization) }
  let(:folder) { create(:folder, space: space) }
  let(:document) { create(:document, uploaded_by: user, space: space) }
  
  before do
    sign_in user
  end
  
  describe 'GET #dashboard' do
    it 'returns http success' do
      get :dashboard
      expect(response).to have_http_status(:success)
    end
    
    it 'assigns favorite spaces' do
      spaces = create_list(:space, 3, organization: organization)
      get :dashboard
      expect(assigns(:favorite_spaces)).to include(*spaces)
    end
    
    it 'assigns recent documents' do
      docs = create_list(:document, 3, uploaded_by: user, space: space)
      get :dashboard
      expect(assigns(:recent_documents)).to include(*docs)
    end
    
    it 'assigns counts' do
      create_list(:space, 3, organization: organization)
      create_list(:document, 5, uploaded_by: user, space: space)
      get :dashboard
      expect(assigns(:spaces_count)).to eq(4) # 3 + 1 already created
      expect(assigns(:documents_count)).to eq(5) # 5 created (document is lazy loaded, not created until accessed)
    end
  end
  
  describe 'GET #show_space' do
    it 'returns http success' do
      get :show_space, params: { id: space.id }
      expect(response).to have_http_status(:success)
    end
    
    it 'assigns the requested space' do
      get :show_space, params: { id: space.id }
      expect(assigns(:space)).to eq(space)
    end
    
    it 'assigns root folders' do
      root_folders = create_list(:folder, 2, space: space, parent: nil)
      child_folder = create(:folder, space: space, parent: root_folders.first)
      get :show_space, params: { id: space.id }
      expect(assigns(:folders)).to include(*root_folders)
      expect(assigns(:folders)).not_to include(child_folder)
    end
    
    it 'assigns documents without folder' do
      doc_without_folder = create(:document, uploaded_by: user, space: space, folder: nil)
      doc_with_folder = create(:document, uploaded_by: user, space: space, folder: folder)
      get :show_space, params: { id: space.id }
      expect(assigns(:documents)).to include(doc_without_folder)
      expect(assigns(:documents)).not_to include(doc_with_folder)
    end
    
    it 'denies access to spaces from other organizations' do
      other_space = create(:space, organization: create(:organization))
      get :show_space, params: { id: other_space.id }
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq('Vous n\'êtes pas autorisé à effectuer cette action.')
    end
  end
  
  describe 'GET #show_folder' do
    it 'returns http success' do
      get :show_folder, params: { id: folder.id }
      expect(response).to have_http_status(:success)
    end
    
    it 'assigns the requested folder' do
      get :show_folder, params: { id: folder.id }
      expect(assigns(:folder)).to eq(folder)
    end
    
    it 'assigns subfolders' do
      subfolders = create_list(:folder, 2, space: space, parent: folder)
      get :show_folder, params: { id: folder.id }
      expect(assigns(:subfolders)).to include(*subfolders)
    end
    
    it 'assigns documents in folder' do
      docs = create_list(:document, 3, uploaded_by: user, space: space, folder: folder)
      get :show_folder, params: { id: folder.id }
      expect(assigns(:documents)).to include(*docs)
    end
    
    it 'denies access to folders from other organizations' do
      other_folder = create(:folder, space: create(:space, organization: create(:organization)))
      get :show_folder, params: { id: other_folder.id }
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq('Vous n\'êtes pas autorisé à effectuer cette action.')
    end
  end
  
  describe 'GET #show_document' do
    it 'returns http success' do
      get :show_document, params: { id: document.id }
      expect(response).to have_http_status(:success)
    end
    
    it 'assigns the requested document' do
      get :show_document, params: { id: document.id }
      expect(assigns(:document)).to eq(document)
    end
    
    it 'denies access to documents from other organizations' do
      other_doc = create(:document, uploaded_by: create(:user), space: create(:space, organization: create(:organization)))
      get :show_document, params: { id: other_doc.id }
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq('Vous n\'êtes pas autorisé à effectuer cette action.')
    end
  end
  
  describe 'POST #create_space' do
    let(:valid_attributes) { { name: 'New Space', description: 'Description' } }
    
    context 'with valid params' do
      it 'creates a new space' do
        expect {
          post :create_space, params: { space: valid_attributes }, format: :json
        }.to change(Space, :count).by(1)
      end
      
      it 'returns success JSON' do
        post :create_space, params: { space: valid_attributes }, format: :json
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['message']).to eq('Espace créé avec succès')
      end
    end
    
    context 'with invalid params' do
      it 'does not create a new space' do
        expect {
          post :create_space, params: { space: { name: '' } }, format: :json
        }.not_to change(Space, :count)
      end
      
      it 'returns error JSON' do
        post :create_space, params: { space: { name: '' } }, format: :json
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['errors']).to be_present
      end
    end
  end
  
  describe 'POST #create_folder' do
    let(:valid_attributes) { { name: 'New Folder', description: 'Description' } }
    
    before do
      request.env['HTTP_REFERER'] = ged_space_path(space)
    end
    
    context 'with valid params' do
      it 'creates a new folder' do
        expect {
          post :create_folder, params: { space_id: space.id, folder: valid_attributes }, format: :json
        }.to change(Folder, :count).by(1)
      end
      
      it 'creates a subfolder when parent_id is provided' do
        post :create_folder, params: { space_id: space.id, folder: valid_attributes, parent_id: folder.id }, format: :json
        new_folder = Folder.last
        expect(new_folder.parent).to eq(folder)
      end
      
      it 'returns success JSON' do
        post :create_folder, params: { space_id: space.id, folder: valid_attributes }, format: :json
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['message']).to eq('Dossier créé avec succès')
      end
    end
    
    context 'with invalid params' do
      it 'does not create a new folder' do
        expect {
          post :create_folder, params: { space_id: space.id, folder: { name: '' } }, format: :json
        }.not_to change(Folder, :count)
      end
      
      it 'returns error JSON' do
        post :create_folder, params: { space_id: space.id, folder: { name: '' } }, format: :json
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['errors']).to be_present
      end
    end
  end
  
  describe 'POST #upload_document' do
    let(:file) { fixture_file_upload('spec/fixtures/test_document.pdf', 'application/pdf') }
    let(:valid_attributes) do
      {
        title: 'Test Document',
        description: 'Description',
        file: file,
        space_id: space.id
      }
    end
    
    context 'with valid params' do
      it 'creates a new document' do
        expect {
          post :upload_document, params: { document: valid_attributes }, format: :json
        }.to change(Document, :count).by(1)
      end
      
      it 'assigns the current user as document owner' do
        post :upload_document, params: { document: valid_attributes }, format: :json
        expect(Document.last.uploaded_by).to eq(user)
      end
      
      it 'returns success JSON' do
        post :upload_document, params: { document: valid_attributes }, format: :json
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['message']).to eq('Document uploadé avec succès. Le traitement est en cours...')
      end
    end
    
    context 'with invalid params' do
      it 'does not create a new document' do
        expect {
          post :upload_document, params: { document: { title: '', space_id: space.id } }, format: :json
        }.not_to change(Document, :count)
      end
      
      it 'returns error JSON' do
        post :upload_document, params: { document: { title: '', space_id: space.id } }, format: :json
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['errors']).to be_present
      end
    end
  end
end