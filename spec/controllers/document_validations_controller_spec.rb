require 'rails_helper'

RSpec.describe DocumentValidationsController, type: :controller do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:validator) { create(:user, organization: organization) }
  let(:space) { create(:space, organization: organization) }
  let(:document) { create(:document, space: space, uploaded_by: user) }
  let(:validation_request) { create(:validation_request, validatable: document, requester: user) }
  let(:document_validation) { create(:document_validation, validation_request: validation_request, validator: validator) }
  
  before do
    sign_in user
  end

  describe 'GET #index' do
    context 'when user is a validator' do
      let(:document2) { create(:document, space: space, uploaded_by: user) }
      let(:validation_request2) { create(:validation_request, validatable: document2, requester: user) }
      
      let!(:pending_validation) { create(:document_validation, 
                                        validation_request: validation_request, 
                                        validator: user,
                                        status: 'pending') }
      let!(:completed_validation) { create(:document_validation, 
                                          validation_request: validation_request2, 
                                          validator: user,
                                          status: 'approved',
                                          validated_at: Time.current) }

      it 'returns a success response' do
        get :index, params: { document_id: document.id }
        expect(response).to be_successful
      end

      it 'assigns pending validations for current user' do
        get :index, params: { document_id: document.id }
        expect(assigns(:pending_validations)).to include(pending_validation)
      end

      it 'assigns completed validations for current user' do
        get :index, params: { document_id: document.id }
        expect(assigns(:completed_validations)).to include(completed_validation)
      end
    end
  end

  describe 'GET #show' do
    before do
      create(:document_validation, validation_request: validation_request, validator: user, status: 'pending')
    end

    it 'returns a success response' do
      get :show, params: { document_id: document.id, id: validation_request.id }
      expect(response).to be_successful
    end

    it 'assigns the requested validation request' do
      get :show, params: { document_id: document.id, id: validation_request.id }
      expect(assigns(:validation_request)).to eq(validation_request)
    end

    it 'assigns document validations' do
      get :show, params: { document_id: document.id, id: validation_request.id }
      expect(assigns(:document_validations)).to be_present
    end

    it 'determines if current user can validate' do
      get :show, params: { document_id: document.id, id: validation_request.id }
      expect(assigns(:can_validate)).to be true
    end
  end

  describe 'GET #new' do
    context 'when user can request validation' do
      before do
        allow_any_instance_of(Document).to receive(:can_request_validation?).and_return(true)
      end

      it 'returns a success response' do
        get :new, params: { document_id: document.id }
        expect(response).to be_successful
      end

      it 'assigns a new validation request' do
        get :new, params: { document_id: document.id }
        expect(assigns(:validation_request)).to be_a_new(ValidationRequest)
      end

      it 'assigns available validators' do
        create(:authorization, user: validator, authorizable: space, permission_level: 'validate')
        get :new, params: { document_id: document.id }
        expect(assigns(:available_validators)).to include(validator)
      end
    end

    context 'when user cannot request validation' do
      before do
        allow_any_instance_of(Document).to receive(:can_request_validation?).and_return(false)
      end

      it 'redirects to document page' do
        get :new, params: { document_id: document.id }
        expect(response).to redirect_to(ged_document_path(document))
      end
    end
  end

  describe 'POST #create' do
    context 'when user can request validation' do
      before do
        allow_any_instance_of(Document).to receive(:can_request_validation?).and_return(true)
      end

      context 'with valid parameters' do
        let(:valid_params) do
          {
            document_id: document.id,
            validation_request: {
              validator_ids: [validator.id.to_s],
              min_validations: '1'
            }
          }
        end

        it 'creates a new validation request' do
          expect {
            post :create, params: valid_params
          }.to change(ValidationRequest, :count).by(1)
        end

        it 'redirects to document page' do
          post :create, params: valid_params
          expect(response).to redirect_to(ged_document_path(document))
        end
      end

      context 'with no validators selected' do
        let(:invalid_params) do
          {
            document_id: document.id,
            validation_request: {
              validator_ids: [''],
              min_validations: '1'
            }
          }
        end

        it 'does not create a validation request' do
          expect {
            post :create, params: invalid_params
          }.not_to change(ValidationRequest, :count)
        end

        it 'redirects with alert' do
          post :create, params: invalid_params
          expect(response).to redirect_to(ged_document_path(document))
          expect(flash[:alert]).to be_present
        end
      end

      context 'when min_validations exceeds validator count' do
        let(:invalid_params) do
          {
            document_id: document.id,
            validation_request: {
              validator_ids: [validator.id.to_s],
              min_validations: '2'
            }
          }
        end

        it 'does not create a validation request' do
          expect {
            post :create, params: invalid_params
          }.not_to change(ValidationRequest, :count)
        end

        it 'redirects with alert' do
          post :create, params: invalid_params
          expect(response).to redirect_to(ged_document_path(document))
          expect(flash[:alert]).to include('nombre minimum')
        end
      end
    end
  end

  describe 'POST #approve' do
    let!(:pending_validation) { create(:document_validation, 
                                      validation_request: validation_request, 
                                      validator: user,
                                      status: 'pending') }

    context 'when user can validate' do
      it 'approves the validation' do
        post :approve, params: { document_id: document.id, id: validation_request.id, comment: 'Approved' }
        pending_validation.reload
        expect(pending_validation.status).to eq('approved')
      end

      it 'redirects to validation request page' do
        post :approve, params: { document_id: document.id, id: validation_request.id, comment: 'Approved' }
        expect(response).to redirect_to(ged_document_validation_path(document, validation_request))
      end

      context 'with JSON format' do
        it 'returns success response' do
          post :approve, params: { document_id: document.id, id: validation_request.id, comment: 'Approved' }, format: :json
          expect(response).to be_successful
          json_response = JSON.parse(response.body)
          expect(json_response['status']).to eq('approved')
        end
      end
    end
  end

  describe 'POST #reject' do
    let!(:pending_validation) { create(:document_validation, 
                                      validation_request: validation_request, 
                                      validator: user,
                                      status: 'pending') }

    context 'with comment' do
      it 'rejects the validation' do
        post :reject, params: { document_id: document.id, id: validation_request.id, comment: 'Issues found' }
        pending_validation.reload
        expect(pending_validation.status).to eq('rejected')
      end

      it 'redirects to validation request page' do
        post :reject, params: { document_id: document.id, id: validation_request.id, comment: 'Issues found' }
        expect(response).to redirect_to(ged_document_validation_path(document, validation_request))
      end

      context 'with JSON format' do
        it 'returns success response' do
          post :reject, params: { document_id: document.id, id: validation_request.id, comment: 'Issues found' }, format: :json
          expect(response).to be_successful
          json_response = JSON.parse(response.body)
          expect(json_response['status']).to eq('rejected')
        end
      end
    end

    context 'without comment' do
      it 'does not reject the validation' do
        post :reject, params: { document_id: document.id, id: validation_request.id }
        pending_validation.reload
        expect(pending_validation.status).to eq('pending')
      end

      it 'redirects with alert' do
        post :reject, params: { document_id: document.id, id: validation_request.id }
        expect(response).to redirect_to(ged_document_validation_path(document, validation_request))
        expect(flash[:alert]).to include('commentaire')
      end

      context 'with JSON format' do
        it 'returns error response' do
          post :reject, params: { document_id: document.id, id: validation_request.id }, format: :json
          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response['message']).to include('Commentaire')
        end
      end
    end
  end

  describe 'GET #my_requests' do
    let!(:user_request) { create(:validation_request, validatable: document, requester: user) }
    let!(:other_request) { create(:validation_request, validatable: document, requester: validator) }

    it 'returns a success response' do
      get :my_requests
      expect(response).to be_successful
    end

    it 'assigns validation requests for current user' do
      get :my_requests
      expect(assigns(:validation_requests)).to include(user_request)
      expect(assigns(:validation_requests)).not_to include(other_request)
    end
  end
end