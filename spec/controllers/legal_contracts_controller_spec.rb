require 'rails_helper'

RSpec.describe LegalContractsController, type: :controller do
  let(:organization) { create(:organization) }
  let(:juridique_user) { create(:user, organization: organization) }
  let(:direction_user) { create(:user, organization: organization) }
  let(:regular_user) { create(:user, organization: organization) }
  let(:client) { create(:client, organization: organization) }
  let(:contract) { create(:contract, client: client, legal_owner: juridique_user, organization: organization) }
  
  before do
    juridique_user.add_role(:juridique)
    direction_user.add_role(:direction)
  end
  
  describe 'GET #index' do
    context 'as juridique user' do
      before { sign_in juridique_user }
      
      it 'returns success' do
        get :index
        expect(response).to have_http_status(:success)
      end
      
      it 'filters contracts by legal status' do
        pending_contract = create(:contract, legal_status: 'pending_review', organization: organization)
        approved_contract = create(:contract, legal_status: 'approved', organization: organization)
        
        get :index, params: { filter: 'pending_review' }
        expect(assigns(:contracts)).to include(pending_contract)
        expect(assigns(:contracts)).not_to include(approved_contract)
      end
      
      it 'calculates compliance summary' do
        get :index
        expect(assigns(:compliance_summary)).to include(
          :total_contracts, :compliant, :non_compliant, :pending_review, :high_risk
        )
      end
      
      it 'assesses contract risks' do
        get :index
        expect(assigns(:risk_assessment)).to be_present
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
    before { sign_in juridique_user }
    
    it 'returns success' do
      get :show, params: { id: contract.id }
      expect(response).to have_http_status(:success)
    end
    
    it 'loads contract legal data' do
      get :show, params: { id: contract.id }
      expect(assigns(:contract)).to eq(contract)
      expect(assigns(:legal_reviews)).to be_present
      expect(assigns(:clauses)).to be_present
      expect(assigns(:compliance_checks)).to be_present
      expect(assigns(:risk_analysis)).to be_present
    end
  end
  
  describe 'GET #new' do
    before { sign_in juridique_user }
    
    it 'returns success' do
      get :new
      expect(response).to have_http_status(:success)
    end
    
    it 'assigns a new legal contract' do
      get :new
      expect(assigns(:contract)).to be_a_new(Contract)
      expect(assigns(:contract).contract_type).to eq('legal')
    end
    
    it 'loads legal templates and clauses' do
      template = create(:legal_template)
      clause = create(:standard_clause)
      
      get :new
      expect(assigns(:legal_templates)).to include(template)
      expect(assigns(:standard_clauses)).to include(clause)
    end
  end
  
  describe 'POST #create' do
    before { sign_in juridique_user }
    
    let(:valid_params) do
      {
        contract: {
          title: 'Legal Agreement',
          client_id: client.id,
          contract_type: 'legal',
          legal_category: 'service',
          governing_law: 'French Law',
          jurisdiction: 'Paris',
          start_date: Date.current,
          end_date: 1.year.from_now
        }
      }
    end
    
    context 'with valid params' do
      it 'creates a new legal contract' do
        expect {
          post :create, params: valid_params
        }.to change(Contract, :count).by(1)
      end
      
      it 'sets legal owner and status' do
        post :create, params: valid_params
        contract = Contract.last
        expect(contract.legal_owner).to eq(juridique_user)
        expect(contract.status).to eq('draft')
      end
      
      it 'enqueues legal review job' do
        expect {
          post :create, params: valid_params
        }.to have_enqueued_job(LegalReviewJob)
      end
      
      it 'attaches standard clauses when provided' do
        clause_ids = create_list(:standard_clause, 2).map(&:id)
        post :create, params: valid_params.merge(standard_clause_ids: clause_ids)
        expect(Contract.last.contract_clauses.count).to eq(2)
      end
      
      it 'redirects to contract' do
        post :create, params: valid_params
        expect(response).to redirect_to(Contract.last)
        expect(flash[:notice]).to eq('Contrat juridique créé avec succès')
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
    
    it 'updates legal contract' do
      put :update, params: { id: contract.id, contract: { governing_law: 'EU Law' } }
      expect(contract.reload.governing_law).to eq('EU Law')
    end
    
    it 'creates legal version' do
      expect_any_instance_of(Contract).to receive(:create_legal_version!).with(juridique_user)
      put :update, params: { id: contract.id, contract: { title: 'Updated' } }
    end
    
    it 'enqueues compliance check' do
      expect {
        put :update, params: { id: contract.id, contract: { title: 'Updated' } }
      }.to have_enqueued_job(ComplianceCheckJob)
    end
  end
  
  describe 'POST #validate' do
    before { sign_in juridique_user }
    
    let(:validation_params) do
      {
        id: contract.id,
        status: 'approved',
        comments: 'Contract meets all legal requirements',
        risk_level: 'low'
      }
    end
    
    it 'creates legal review' do
      expect {
        post :validate, params: validation_params
      }.to change(LegalReview, :count).by(1)
    end
    
    it 'updates contract legal status' do
      expect_any_instance_of(Contract).to receive(:update_legal_status!)
      post :validate, params: validation_params
    end
    
    it 'sends notification' do
      expect_any_instance_of(NotificationService).to receive(:notify_legal_validation)
      post :validate, params: validation_params
    end
    
    it 'redirects with success' do
      post :validate, params: validation_params
      expect(response).to redirect_to(contract)
      expect(flash[:notice]).to eq('Validation juridique enregistrée')
    end
  end
  
  describe 'GET #review' do
    before { sign_in juridique_user }
    
    it 'returns success' do
      get :review, params: { id: contract.id }
      expect(response).to have_http_status(:success)
    end
    
    it 'loads review data' do
      get :review, params: { id: contract.id }
      expect(assigns(:review_checklist)).to be_present
      expect(assigns(:previous_reviews)).to be_present
      expect(assigns(:compliance_issues)).to be_present
    end
  end
  
  describe 'POST #archive' do
    before { sign_in juridique_user }
    
    context 'when contract can be archived' do
      before { allow(contract).to receive(:can_be_archived?).and_return(true) }
      
      it 'archives contract' do
        expect(contract).to receive(:archive!).with(
          reason: 'Completed',
          archived_by: juridique_user
        )
        post :archive, params: { id: contract.id, reason: 'Completed' }
      end
      
      it 'redirects to index' do
        post :archive, params: { id: contract.id, reason: 'Completed' }
        expect(response).to redirect_to(legal_contracts_path)
        expect(flash[:notice]).to eq('Contrat archivé avec succès')
      end
    end
    
    context 'when contract cannot be archived' do
      before { allow(contract).to receive(:can_be_archived?).and_return(false) }
      
      it 'redirects with error' do
        post :archive, params: { id: contract.id }
        expect(response).to redirect_to(contract)
        expect(flash[:alert]).to eq('Ce contrat ne peut pas être archivé')
      end
    end
  end
  
  describe 'GET #compliance_dashboard' do
    before { sign_in juridique_user }
    
    it 'returns success' do
      get :compliance_dashboard
      expect(response).to have_http_status(:success)
    end
    
    it 'loads compliance data' do
      get :compliance_dashboard
      expect(assigns(:compliance_metrics)).to include(
        :overall_compliance_rate, :gdpr_compliance, 
        :regulatory_violations, :upcoming_audits
      )
      expect(assigns(:upcoming_deadlines)).to be_present
      expect(assigns(:non_compliant_contracts)).to be_present
      expect(assigns(:regulatory_updates)).to be_present
    end
  end
  
  describe 'GET #clause_library' do
    before { sign_in juridique_user }
    
    it 'returns success' do
      get :clause_library
      expect(response).to have_http_status(:success)
    end
    
    it 'loads clauses and categories' do
      clause = create(:standard_clause)
      category = create(:clause_category)
      
      get :clause_library
      expect(assigns(:clauses)).to include(clause)
      expect(assigns(:categories)).to include(category)
      expect(assigns(:recent_updates)).to be_present
    end
  end
  
  describe 'GET #generate_legal_report' do
    before { sign_in juridique_user }
    
    it 'generates PDF report' do
      allow_any_instance_of(LegalReportService).to receive(:generate)
        .and_return(double(to_pdf: 'PDF content'))
      
      get :generate_legal_report, format: :pdf
      expect(response.content_type).to eq('application/pdf')
      expect(response.headers['Content-Disposition']).to include('legal_report')
    end
    
    it 'generates Excel report' do
      allow_any_instance_of(LegalReportService).to receive(:generate)
        .and_return(double(to_excel: 'Excel content'))
      
      get :generate_legal_report, format: :xlsx
      expect(response.content_type).to eq('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
    end
  end
  
  describe 'authorization' do
    it 'allows juridique users' do
      sign_in juridique_user
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