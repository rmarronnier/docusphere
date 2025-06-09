require 'rails_helper'

RSpec.describe BasketsController, type: :controller do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let!(:basket) { create(:basket, user: user) }
  
  before do
    sign_in user
    # Bypass Pundit authorization checks for testing
    allow(controller).to receive(:verify_authorized).and_return(true)
    allow(controller).to receive(:verify_policy_scoped).and_return(true)
  end

  describe 'GET #index' do
    it 'returns a success response' do
      get :index
      expect(response).to be_successful
    end

    it 'assigns current user baskets' do
      basket
      get :index
      expect(assigns(:baskets)).to include(basket)
    end

    it 'only shows current user baskets' do
      other_user = create(:user, organization: organization)
      other_basket = create(:basket, user: other_user)
      
      get :index
      expect(assigns(:baskets)).to include(basket)
      expect(assigns(:baskets)).not_to include(other_basket)
    end
  end

  describe 'GET #show' do
    it 'returns a success response' do
      get :show, params: { id: basket.id }
      expect(response).to be_successful
    end

    it 'assigns the requested basket' do
      get :show, params: { id: basket.id }
      expect(assigns(:basket)).to eq(basket)
    end

    it 'assigns basket items' do
      document = create(:document, space: create(:space, organization: organization))
      basket_item = create(:basket_item, basket: basket, item: document)
      
      get :show, params: { id: basket.id }
      expect(assigns(:basket_items)).to include(basket_item)
    end

    it 'prevents access to other users baskets' do
      other_user = create(:user, organization: organization)
      other_basket = create(:basket, user: other_user)
      
      expect {
        get :show, params: { id: other_basket.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'GET #new' do
    it 'returns a success response' do
      get :new
      expect(response).to be_successful
    end

    it 'assigns a new basket' do
      get :new
      expect(assigns(:basket)).to be_a_new(Basket)
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      let(:valid_attributes) { { name: 'Test Basket', description: 'Test Description' } }

      it 'creates a new Basket' do
        expect {
          post :create, params: { basket: valid_attributes }
        }.to change(Basket, :count).by(1)
      end

      it 'assigns the basket to current user' do
        post :create, params: { basket: valid_attributes }
        expect(assigns(:basket).user).to eq(user)
      end

      it 'redirects to the created basket' do
        post :create, params: { basket: valid_attributes }
        expect(response).to redirect_to(basket_path(Basket.last))
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { { name: '', description: 'Test Description' } }

      it 'does not create a new Basket' do
        expect {
          post :create, params: { basket: invalid_attributes }
        }.to change(Basket, :count).by(0)
      end

      it 'renders new template' do
        post :create, params: { basket: invalid_attributes }
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'GET #edit' do
    it 'returns a success response' do
      get :edit, params: { id: basket.id }
      expect(response).to be_successful
    end

    it 'assigns the requested basket' do
      get :edit, params: { id: basket.id }
      expect(assigns(:basket)).to eq(basket)
    end
  end

  describe 'PATCH #update' do
    context 'with valid parameters' do
      let(:new_attributes) { { name: 'Updated Basket Name' } }

      it 'updates the requested basket' do
        patch :update, params: { id: basket.id, basket: new_attributes }
        basket.reload
        expect(basket.name).to eq('Updated Basket Name')
      end

      it 'redirects to the basket' do
        patch :update, params: { id: basket.id, basket: new_attributes }
        expect(response).to redirect_to(basket_path(basket))
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { { name: '' } }

      it 'does not update the basket' do
        original_name = basket.name
        patch :update, params: { id: basket.id, basket: invalid_attributes }
        basket.reload
        expect(basket.name).to eq(original_name)
      end

      it 'renders edit template' do
        patch :update, params: { id: basket.id, basket: invalid_attributes }
        expect(response).to render_template(:edit)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested basket' do
      basket
      expect {
        delete :destroy, params: { id: basket.id }
      }.to change(Basket, :count).by(-1)
    end

    it 'redirects to the baskets list' do
      delete :destroy, params: { id: basket.id }
      expect(response).to redirect_to(baskets_path)
    end
  end

  describe 'POST #add_document' do
    let(:space) { create(:space, organization: organization) }
    let(:document) { create(:document, space: space, uploaded_by: user) }

    before do
      # Create authorization for document access
      create(:authorization, 
             authorizable: space,
             user: user, 
             permission_level: 'read',
             granted_by: user)
    end

    it 'adds document to basket' do
      allow_any_instance_of(Document).to receive(:readable_by?).and_return(true)
      
      expect {
        post :add_document, params: { id: basket.id, document_id: document.id }
      }.to change { basket.reload.basket_items.count }.by(1)
    end

    it 'returns success response for JSON' do
      allow_any_instance_of(Document).to receive(:readable_by?).and_return(true)
      
      post :add_document, params: { id: basket.id, document_id: document.id }, format: :json
      expect(response).to be_successful
    end

    it 'prevents adding inaccessible documents' do
      allow_any_instance_of(Document).to receive(:readable_by?).and_return(false)
      
      post :add_document, params: { id: basket.id, document_id: document.id }
      expect(response).to redirect_to(baskets_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe 'DELETE #remove_document' do
    let(:space) { create(:space, organization: organization) }
    let(:document) { create(:document, space: space, uploaded_by: user) }

    before do
      basket.add_document(document)
    end

    it 'removes document from basket' do
      expect {
        delete :remove_document, params: { id: basket.id, document_id: document.id }
      }.to change { basket.reload.basket_items.count }.by(-1)
    end

    it 'returns success response for JSON' do
      delete :remove_document, params: { id: basket.id, document_id: document.id }, format: :json
      expect(response).to be_successful
    end

    it 'redirects to basket show page for HTML' do
      delete :remove_document, params: { id: basket.id, document_id: document.id }
      expect(response).to redirect_to(basket_path(basket))
    end
  end

  describe 'POST #share' do
    it 'marks basket as shared' do
      expect {
        post :share, params: { id: basket.id }
      }.to change { basket.reload.is_shared }.from(false).to(true)
    end

    it 'redirects to basket show page' do
      post :share, params: { id: basket.id }
      expect(response).to redirect_to(basket_path(basket))
      expect(flash[:notice]).to be_present
    end
  end

  describe 'GET #download_all' do
    it 'redirects with future feature message' do
      get :download_all, params: { id: basket.id }
      expect(response).to redirect_to(basket_path(basket))
      expect(flash[:notice]).to include('à venir')
    end
  end

  describe 'authentication' do
    before { sign_out user }

    it 'redirects to login for index' do
      get :index
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects to login for show' do
      get :show, params: { id: basket.id }
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end