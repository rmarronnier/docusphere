require 'rails_helper'

RSpec.describe TagsController, type: :controller do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:tag) { create(:tag) }
  
  before do
    sign_in user
  end

  describe 'GET #index' do
    it 'returns a success response' do
      get :index
      expect(response).to be_successful
    end

    it 'assigns all tags' do
      tag
      get :index
      expect(assigns(:tags)).to include(tag)
    end

    context 'with search parameter' do
      let!(:searched_tag) { create(:tag, name: 'contract') }
      let!(:other_tag) { create(:tag, name: 'invoice') }

      it 'filters tags by name' do
        get :index, params: { search: 'contract' }
        expect(assigns(:tags)).to include(searched_tag)
        expect(assigns(:tags)).not_to include(other_tag)
      end
    end

    context 'with format JSON' do
      it 'returns JSON response' do
        get :index, format: :json
        expect(response).to be_successful
        expect(response.content_type).to include('application/json')
      end

      it 'includes tag suggestions' do
        tag
        get :index, params: { search: tag.name[0..2] }, format: :json
        json_response = JSON.parse(response.body)
        expect(json_response).to be_an(Array)
      end
    end
  end

  describe 'GET #show' do
    it 'returns a success response' do
      get :show, params: { id: tag.id }
      expect(response).to be_successful
    end

    it 'assigns the requested tag' do
      get :show, params: { id: tag.id }
      expect(assigns(:tag)).to eq(tag)
    end

    it 'assigns tagged documents' do
      space = create(:space, organization: organization)
      document = create(:document, space: space)
      document.tags << tag
      
      get :show, params: { id: tag.id }
      expect(assigns(:documents)).to include(document)
    end
  end

  describe 'GET #new' do
    it 'returns a success response' do
      get :new
      expect(response).to be_successful
    end

    it 'assigns a new tag' do
      get :new
      expect(assigns(:tag)).to be_a_new(Tag)
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      let(:valid_attributes) { { name: 'New Tag', description: 'Tag Description', color: '#FF0000' } }

      it 'creates a new Tag' do
        expect {
          post :create, params: { tag: valid_attributes }
        }.to change(Tag, :count).by(1)
      end

      it 'redirects to the created tag' do
        post :create, params: { tag: valid_attributes }
        expect(response).to redirect_to(tag_path(Tag.last))
      end

      context 'with AJAX request' do
        it 'returns JSON response' do
          post :create, params: { tag: valid_attributes }, xhr: true
          expect(response).to be_successful
          expect(response.content_type).to include('application/json')
        end

        it 'includes tag data in response' do
          post :create, params: { tag: valid_attributes }, xhr: true
          json_response = JSON.parse(response.body)
          expect(json_response['success']).to be true
          expect(json_response['tag']['name']).to eq('New Tag')
        end
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { { name: '', description: 'Tag Description' } }

      it 'does not create a new Tag' do
        expect {
          post :create, params: { tag: invalid_attributes }
        }.to change(Tag, :count).by(0)
      end

      it 'renders new template' do
        post :create, params: { tag: invalid_attributes }
        expect(response).to render_template(:new)
      end

      context 'with AJAX request' do
        it 'returns error response' do
          post :create, params: { tag: invalid_attributes }, xhr: true
          json_response = JSON.parse(response.body)
          expect(json_response['success']).to be false
          expect(json_response['errors']).to be_present
        end
      end
    end

    context 'with duplicate tag name' do
      before { create(:tag, name: 'Duplicate') }

      it 'does not create duplicate tag' do
        expect {
          post :create, params: { tag: { name: 'Duplicate', description: 'Test' } }
        }.to change(Tag, :count).by(0)
      end
    end
  end

  describe 'GET #edit' do
    it 'returns a success response' do
      get :edit, params: { id: tag.id }
      expect(response).to be_successful
    end

    it 'assigns the requested tag' do
      get :edit, params: { id: tag.id }
      expect(assigns(:tag)).to eq(tag)
    end
  end

  describe 'PATCH #update' do
    context 'with valid parameters' do
      let(:new_attributes) { { name: 'Updated Tag Name', color: '#00FF00' } }

      it 'updates the requested tag' do
        patch :update, params: { id: tag.id, tag: new_attributes }
        tag.reload
        expect(tag.name).to eq('Updated Tag Name')
        expect(tag.color).to eq('#00FF00')
      end

      it 'redirects to the tag' do
        patch :update, params: { id: tag.id, tag: new_attributes }
        expect(response).to redirect_to(tag_path(tag))
      end

      context 'with AJAX request' do
        it 'returns success JSON response' do
          patch :update, params: { id: tag.id, tag: new_attributes }, xhr: true
          expect(response).to be_successful
          json_response = JSON.parse(response.body)
          expect(json_response['success']).to be true
        end
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { { name: '' } }

      it 'does not update the tag' do
        original_name = tag.name
        patch :update, params: { id: tag.id, tag: invalid_attributes }
        tag.reload
        expect(tag.name).to eq(original_name)
      end

      it 'renders edit template' do
        patch :update, params: { id: tag.id, tag: invalid_attributes }
        expect(response).to render_template(:edit)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested tag' do
      tag
      expect {
        delete :destroy, params: { id: tag.id }
      }.to change(Tag, :count).by(-1)
    end

    it 'redirects to the tags list' do
      delete :destroy, params: { id: tag.id }
      expect(response).to redirect_to(tags_path)
    end

    context 'with AJAX request' do
      it 'returns success JSON response' do
        delete :destroy, params: { id: tag.id }, xhr: true
        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
      end
    end

    context 'when tag has associated documents' do
      let(:space) { create(:space, organization: organization) }
      let(:document) { create(:document, space: space) }

      before do
        document.tags << tag
      end

      it 'removes tag from documents' do
        expect {
          delete :destroy, params: { id: tag.id }
        }.to change { document.reload.tags.count }.by(-1)
      end
    end
  end

  describe 'POST #merge' do
    let(:target_tag) { create(:tag, name: 'Target Tag') }
    let(:source_tags) { create_list(:tag, 2) }
    let(:space) { create(:space, organization: organization) }
    let(:document) { create(:document, space: space) }

    before do
      source_tags.each { |source_tag| document.tags << source_tag }
    end

    it 'merges tags successfully' do
      post :merge, params: { 
        id: target_tag.id, 
        source_tag_ids: source_tags.map(&:id) 
      }
      
      expect(response).to redirect_to(tag_path(target_tag))
      expect(Tag.where(id: source_tags.map(&:id))).to be_empty
    end

    it 'transfers document associations' do
      post :merge, params: { 
        id: target_tag.id, 
        source_tag_ids: source_tags.map(&:id) 
      }
      
      document.reload
      expect(document.tags).to include(target_tag)
      expect(document.tags.where(id: source_tags.map(&:id))).to be_empty
    end

    context 'with AJAX request' do
      it 'returns JSON response' do
        post :merge, params: { 
          id: target_tag.id, 
          source_tag_ids: source_tags.map(&:id) 
        }, xhr: true
        
        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
      end
    end
  end

  describe 'GET #usage_stats' do
    let(:space) { create(:space, organization: organization) }
    let(:documents) { create_list(:document, 3, space: space) }

    before do
      documents.each { |doc| doc.tags << tag }
    end

    it 'returns usage statistics' do
      get :usage_stats, params: { id: tag.id }
      expect(response).to be_successful
      expect(assigns(:usage_count)).to eq(3)
    end

    context 'with JSON format' do
      it 'returns JSON statistics' do
        get :usage_stats, params: { id: tag.id }, format: :json
        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response['usage_count']).to eq(3)
      end
    end
  end

  describe 'authentication' do
    before { sign_out user }

    it 'redirects to login for index' do
      get :index
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects to login for show' do
      get :show, params: { id: tag.id }
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end