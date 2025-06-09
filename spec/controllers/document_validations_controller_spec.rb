require 'rails_helper'

RSpec.describe DocumentValidationsController, type: :controller do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:validator) { create(:user, organization: organization) }
  let(:space) { create(:space, organization: organization) }
  let(:document) { create(:document, space: space, uploaded_by: user) }
  let(:validation_request) { create(:validation_request, document: document, requester: user) }
  let(:document_validation) { create(:document_validation, validation_request: validation_request, validator: validator) }
  
  before do
    sign_in user
  end

  describe 'GET #index' do
    it 'returns a success response' do
      get :index
      expect(response).to be_successful
    end

    it 'assigns validation requests for current user' do
      validation_request
      get :index
      expect(assigns(:validation_requests)).to include(validation_request)
    end

    it 'assigns pending validations for current user as validator' do
      pending_validation = create(:document_validation, 
                                  validation_request: validation_request, 
                                  validator: user,
                                  status: 'pending')
      
      get :index
      expect(assigns(:pending_validations)).to include(pending_validation)
    end

    context 'with status filter' do
      let!(:pending_request) { create(:validation_request, document: document, requester: user, status: 'pending') }
      let!(:completed_request) { create(:validation_request, document: document, requester: user, status: 'completed') }

      it 'filters by pending status' do
        get :index, params: { status: 'pending' }
        expect(assigns(:validation_requests)).to include(pending_request)
        expect(assigns(:validation_requests)).not_to include(completed_request)
      end

      it 'filters by completed status' do
        get :index, params: { status: 'completed' }
        expect(assigns(:validation_requests)).to include(completed_request)
        expect(assigns(:validation_requests)).not_to include(pending_request)
      end
    end
  end

  describe 'GET #show' do
    it 'returns a success response' do
      get :show, params: { id: document_validation.id }
      expect(response).to be_successful
    end

    it 'assigns the requested validation' do
      get :show, params: { id: document_validation.id }
      expect(assigns(:validation)).to eq(document_validation)
    end

    it 'assigns the validation request' do
      get :show, params: { id: document_validation.id }
      expect(assigns(:validation_request)).to eq(validation_request)
    end

    it 'assigns the document' do
      get :show, params: { id: document_validation.id }
      expect(assigns(:document)).to eq(document)
    end

    it 'prevents access to validations from other organizations' do
      other_org = create(:organization)
      other_user = create(:user, organization: other_org)
      other_space = create(:space, organization: other_org)
      other_document = create(:document, space: other_space, uploaded_by: other_user)
      other_request = create(:validation_request, document: other_document, requester: other_user)
      other_validation = create(:document_validation, validation_request: other_request, validator: other_user)
      
      expect {
        get :show, params: { id: other_validation.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'POST #create' do
    let(:validation_request) { create(:validation_request, document: document, requester: user) }

    context 'with valid parameters' do
      let(:valid_attributes) do
        {
          validation_request_id: validation_request.id,
          validator_id: validator.id,
          status: 'pending',
          comments: 'Please review this document'
        }
      end

      it 'creates a new DocumentValidation' do
        expect {
          post :create, params: { document_validation: valid_attributes }
        }.to change(DocumentValidation, :count).by(1)
      end

      it 'assigns the validation to the request' do
        post :create, params: { document_validation: valid_attributes }
        expect(assigns(:validation).validation_request).to eq(validation_request)
      end

      it 'redirects to the validation request' do
        post :create, params: { document_validation: valid_attributes }
        expect(response).to redirect_to(validation_request_path(validation_request))
      end

      it 'sends notification to validator' do
        expect {
          post :create, params: { document_validation: valid_attributes }
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { { validation_request_id: nil, validator_id: nil } }

      it 'does not create a new DocumentValidation' do
        expect {
          post :create, params: { document_validation: invalid_attributes }
        }.to change(DocumentValidation, :count).by(0)
      end

      it 'renders new template' do
        post :create, params: { document_validation: invalid_attributes }
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'PATCH #update' do
    context 'when user is the validator' do
      before { sign_in validator }

      context 'with valid parameters' do
        let(:new_attributes) do
          {
            status: 'approved',
            comments: 'Document approved after review',
            decision_reason: 'All requirements met'
          }
        end

        it 'updates the validation' do
          patch :update, params: { id: document_validation.id, document_validation: new_attributes }
          document_validation.reload
          expect(document_validation.status).to eq('approved')
          expect(document_validation.comments).to eq('Document approved after review')
        end

        it 'updates validated_at timestamp' do
          patch :update, params: { id: document_validation.id, document_validation: new_attributes }
          document_validation.reload
          expect(document_validation.validated_at).to be_present
        end

        it 'redirects to the validation' do
          patch :update, params: { id: document_validation.id, document_validation: new_attributes }
          expect(response).to redirect_to(document_validation_path(document_validation))
        end

        it 'sends notification to requester' do
          expect {
            patch :update, params: { id: document_validation.id, document_validation: new_attributes }
          }.to change { ActionMailer::Base.deliveries.count }.by(1)
        end

        context 'when approving' do
          it 'marks validation as approved' do
            patch :update, params: { 
              id: document_validation.id, 
              document_validation: { status: 'approved', comments: 'Approved' } 
            }
            document_validation.reload
            expect(document_validation.status).to eq('approved')
          end
        end

        context 'when rejecting' do
          it 'marks validation as rejected' do
            patch :update, params: { 
              id: document_validation.id, 
              document_validation: { status: 'rejected', comments: 'Does not meet requirements' } 
            }
            document_validation.reload
            expect(document_validation.status).to eq('rejected')
          end
        end
      end

      context 'with invalid parameters' do
        let(:invalid_attributes) { { status: 'invalid_status' } }

        it 'does not update the validation' do
          original_status = document_validation.status
          patch :update, params: { id: document_validation.id, document_validation: invalid_attributes }
          document_validation.reload
          expect(document_validation.status).to eq(original_status)
        end

        it 'renders edit template' do
          patch :update, params: { id: document_validation.id, document_validation: invalid_attributes }
          expect(response).to render_template(:edit)
        end
      end
    end

    context 'when user is not the validator' do
      it 'prevents unauthorized updates' do
        expect {
          patch :update, params: { 
            id: document_validation.id, 
            document_validation: { status: 'approved' } 
          }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when user is the requester' do
      it 'destroys the validation' do
        document_validation
        expect {
          delete :destroy, params: { id: document_validation.id }
        }.to change(DocumentValidation, :count).by(-1)
      end

      it 'redirects to validations index' do
        delete :destroy, params: { id: document_validation.id }
        expect(response).to redirect_to(document_validations_path)
      end
    end

    context 'when validation is already completed' do
      before { document_validation.update(status: 'approved', validated_at: Time.current) }

      it 'prevents deletion of completed validations' do
        expect {
          delete :destroy, params: { id: document_validation.id }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context 'when user is not authorized' do
      let(:other_user) { create(:user, organization: organization) }
      before { sign_in other_user }

      it 'prevents unauthorized deletion' do
        expect {
          delete :destroy, params: { id: document_validation.id }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe 'POST #approve' do
    before { sign_in validator }

    it 'approves the validation' do
      post :approve, params: { 
        id: document_validation.id, 
        comments: 'Approved after review' 
      }
      document_validation.reload
      expect(document_validation.status).to eq('approved')
    end

    it 'sets validated_at timestamp' do
      post :approve, params: { id: document_validation.id }
      document_validation.reload
      expect(document_validation.validated_at).to be_present
    end

    it 'returns success for AJAX requests' do
      post :approve, params: { id: document_validation.id }, xhr: true
      expect(response).to be_successful
    end
  end

  describe 'POST #reject' do
    before { sign_in validator }

    it 'rejects the validation' do
      post :reject, params: { 
        id: document_validation.id, 
        comments: 'Does not meet requirements' 
      }
      document_validation.reload
      expect(document_validation.status).to eq('rejected')
    end

    it 'requires rejection reason' do
      post :reject, params: { id: document_validation.id }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns success for AJAX requests with reason' do
      post :reject, params: { 
        id: document_validation.id, 
        comments: 'Missing required information' 
      }, xhr: true
      expect(response).to be_successful
    end
  end

  describe 'POST #request_changes' do
    before { sign_in validator }

    it 'requests changes for the validation' do
      post :request_changes, params: { 
        id: document_validation.id, 
        comments: 'Please update section 3' 
      }
      document_validation.reload
      expect(document_validation.status).to eq('changes_requested')
    end

    it 'requires change request reason' do
      post :request_changes, params: { id: document_validation.id }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'GET #history' do
    it 'returns validation history' do
      get :history, params: { id: document_validation.id }
      expect(response).to be_successful
      expect(assigns(:history)).to be_present
    end

    context 'with JSON format' do
      it 'returns history in JSON format' do
        get :history, params: { id: document_validation.id }, format: :json
        expect(response).to be_successful
        expect(response.content_type).to include('application/json')
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
      get :show, params: { id: document_validation.id }
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end