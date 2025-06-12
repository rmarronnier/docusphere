require 'rails_helper'

RSpec.describe ContractsController, type: :controller do
  let(:organization) { create(:organization) }
  let(:commercial_user) { create(:user, organization: organization) }
  let(:juridique_user) { create(:user, organization: organization) }
  let(:regular_user) { create(:user, organization: organization) }
  let(:client) { create(:client, organization: organization) }
  let(:contract) { create(:contract, client: client, created_by: commercial_user, organization: organization) }
  
  before do
    commercial_user.add_role(:commercial)
    juridique_user.add_role(:juridique)
  end
  
  describe 'GET #index' do
    context 'as authorized user' do
      before { sign_in commercial_user }
      
      it 'returns success' do
        get :index
        expect(response).to have_http_status(:success)
      end
      
      it 'filters contracts by status' do
        active_contract = create(:contract, status: 'active', organization: organization)
        pending_contract = create(:contract, status: 'pending', organization: organization)
        
        get :index, params: { filter: 'active' }
        expect(assigns(:contracts)).to include(active_contract)
        expect(assigns(:contracts)).not_to include(pending_contract)
      end
      
      it 'loads upcoming renewals' do
        get :index
        expect(assigns(:upcoming_renewals)).to be_present
      end
      
      it 'calculates contract statistics' do
        get :index
        expect(assigns(:stats)).to include(
          :total, :active, :total_value, :expiring_soon, :pending_signature
        )
      end
    end
    
    context 'as unauthorized user' do
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
      get :show, params: { id: contract.id }
      expect(response).to have_http_status(:success)
    end
    
    it 'loads contract data' do
      get :show, params: { id: contract.id }
      expect(assigns(:contract)).to eq(contract)
      expect(assigns(:documents)).to be_present
      expect(assigns(:signatories)).to be_present
      expect(assigns(:financial_summary)).to be_present
    end
  end
  
  describe 'GET #new' do
    before { sign_in commercial_user }
    
    it 'returns success' do
      get :new
      expect(response).to have_http_status(:success)
    end
    
    it 'assigns a new contract' do
      get :new
      expect(assigns(:contract)).to be_a_new(Contract)
    end
    
    it 'pre-fills client when provided' do
      get :new, params: { client_id: client.id }
      expect(assigns(:contract).client_id).to eq(client.id)
    end
    
    it 'loads templates' do
      template = create(:contract_template)
      get :new
      expect(assigns(:templates)).to include(template)
    end
  end
  
  describe 'POST #create' do
    before { sign_in commercial_user }
    
    let(:valid_params) do
      {
        contract: {
          title: 'Service Agreement',
          client_id: client.id,
          contract_type: 'service',
          start_date: Date.current,
          end_date: 1.year.from_now,
          amount: 10000,
          currency: 'EUR',
          payment_terms: 'monthly'
        }
      }
    end
    
    context 'with valid params' do
      it 'creates a new contract' do
        expect {
          post :create, params: valid_params
        }.to change(Contract, :count).by(1)
      end
      
      it 'sets created_by and status' do
        post :create, params: valid_params
        contract = Contract.last
        expect(contract.created_by).to eq(commercial_user)
        expect(contract.status).to eq('draft')
      end
      
      it 'enqueues notification job' do
        expect {
          post :create, params: valid_params
        }.to have_enqueued_job(ContractNotificationJob)
      end
      
      it 'redirects to contract' do
        post :create, params: valid_params
        expect(response).to redirect_to(Contract.last)
        expect(flash[:notice]).to eq('Contrat créé avec succès')
      end
    end
    
    context 'with document attachment' do
      let(:document_file) { fixture_file_upload('contract.pdf', 'application/pdf') }
      
      it 'attaches document to contract' do
        post :create, params: valid_params.merge(document: document_file)
        expect(Contract.last.documents.count).to eq(1)
      end
    end
    
    context 'with invalid params' do
      it 'does not create contract' do
        expect {
          post :create, params: { contract: { title: '' } }
        }.not_to change(Contract, :count)
      end
      
      it 'renders new template' do
        post :create, params: { contract: { title: '' } }
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
  
  describe 'PUT #update' do
    before { sign_in juridique_user }
    
    it 'updates contract' do
      put :update, params: { id: contract.id, contract: { title: 'Updated Title' } }
      expect(contract.reload.title).to eq('Updated Title')
    end
    
    it 'creates version' do
      expect_any_instance_of(Contract).to receive(:create_version!).with(juridique_user)
      put :update, params: { id: contract.id, contract: { title: 'Updated Title' } }
    end
    
    it 'redirects to contract' do
      put :update, params: { id: contract.id, contract: { title: 'Updated Title' } }
      expect(response).to redirect_to(contract)
      expect(flash[:notice]).to eq('Contrat mis à jour avec succès')
    end
  end
  
  describe 'DELETE #destroy' do
    before { sign_in commercial_user }
    
    context 'when contract can be deleted' do
      before { allow(contract).to receive(:can_be_deleted?).and_return(true) }
      
      it 'destroys contract' do
        contract # create it
        expect {
          delete :destroy, params: { id: contract.id }
        }.to change(Contract, :count).by(-1)
      end
      
      it 'redirects to index' do
        delete :destroy, params: { id: contract.id }
        expect(response).to redirect_to(contracts_path)
        expect(flash[:notice]).to eq('Contrat supprimé')
      end
    end
    
    context 'when contract cannot be deleted' do
      before { allow(contract).to receive(:can_be_deleted?).and_return(false) }
      
      it 'does not destroy contract' do
        contract # create it
        expect {
          delete :destroy, params: { id: contract.id }
        }.not_to change(Contract, :count)
      end
      
      it 'redirects with error' do
        delete :destroy, params: { id: contract.id }
        expect(response).to redirect_to(contract)
        expect(flash[:alert]).to eq('Ce contrat ne peut pas être supprimé')
      end
    end
  end
  
  describe 'POST #sign' do
    before { sign_in commercial_user }
    
    let(:signatory) { create(:contract_signatory, contract: contract, email: 'signer@example.com') }
    
    context 'with valid signature' do
      before do
        allow(signatory).to receive(:can_sign?).and_return(true)
        allow(signatory).to receive(:sign!)
      end
      
      it 'signs the contract' do
        expect(signatory).to receive(:sign!).with('signature_data')
        post :sign, params: { id: contract.id, email: signatory.email, signature_data: 'signature_data' }
      end
      
      it 'activates contract when all signed' do
        allow(contract).to receive(:all_signed?).and_return(true)
        expect(contract).to receive(:activate!)
        post :sign, params: { id: contract.id, email: signatory.email, signature_data: 'signature_data' }
      end
    end
    
    context 'with invalid signature' do
      before { allow_any_instance_of(Contract).to receive_message_chain(:signatories, :find_by).and_return(nil) }
      
      it 'redirects with error' do
        post :sign, params: { id: contract.id, email: 'invalid@example.com' }
        expect(response).to redirect_to(contract)
        expect(flash[:alert]).to eq('Signature non autorisée')
      end
    end
  end
  
  describe 'POST #renew' do
    before { sign_in juridique_user }
    
    it 'creates renewed contract' do
      allow(contract).to receive(:duplicate_for_renewal).and_return(Contract.new(contract.attributes))
      allow(contract).to receive(:duration_in_months).and_return(12)
      
      expect {
        post :renew, params: { id: contract.id }
      }.to change(Contract, :count).by(1)
    end
    
    it 'marks original as renewed' do
      expect(contract).to receive(:mark_as_renewed!)
      post :renew, params: { id: contract.id }
    end
  end
  
  describe 'POST #terminate' do
    before { sign_in juridique_user }
    
    context 'when contract can be terminated' do
      before { allow(contract).to receive(:can_be_terminated?).and_return(true) }
      
      it 'terminates contract' do
        expect(contract).to receive(:terminate!).with(
          reason: 'Mutual agreement',
          termination_date: '2024-12-31'
        )
        post :terminate, params: { 
          id: contract.id, 
          reason: 'Mutual agreement',
          termination_date: '2024-12-31'
        }
      end
      
      it 'sends notification' do
        expect {
          post :terminate, params: { id: contract.id, reason: 'Test' }
        }.to have_enqueued_job(ContractNotificationJob)
      end
    end
  end
  
  describe 'authorization' do
    it 'allows commercial users' do
      sign_in commercial_user
      get :index
      expect(response).to have_http_status(:success)
    end
    
    it 'allows juridique users' do
      sign_in juridique_user
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