require 'rails_helper'

RSpec.describe LegalDeadlinesController, type: :controller do
  let(:organization) { create(:organization) }
  let(:juridique_user) { create(:user, organization: organization) }
  let(:direction_user) { create(:user, organization: organization) }
  let(:regular_user) { create(:user, organization: organization) }
  let(:contract) { create(:contract, organization: organization) }
  let(:deadline) { create(:legal_deadline, created_by: juridique_user, organization: organization) }
  
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
      
      it 'filters deadlines by status' do
        upcoming_deadline = create(:legal_deadline, due_date: 5.days.from_now, organization: organization)
        overdue_deadline = create(:legal_deadline, due_date: 5.days.ago, organization: organization)
        
        get :index, params: { filter: 'upcoming' }
        expect(assigns(:deadlines)).to include(upcoming_deadline)
        expect(assigns(:deadlines)).not_to include(overdue_deadline)
      end
      
      it 'builds calendar data' do
        deadline # create it
        get :index
        expect(assigns(:calendar_deadlines)).to be_present
        expect(assigns(:calendar_deadlines).first).to include(:id, :title, :start, :color)
      end
      
      it 'calculates statistics' do
        get :index
        expect(assigns(:statistics)).to include(
          :total, :overdue, :upcoming_7_days, :upcoming_30_days,
          :completion_rate, :average_completion_time
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
    before { sign_in juridique_user }
    
    it 'returns success' do
      get :show, params: { id: deadline.id }
      expect(response).to have_http_status(:success)
    end
    
    it 'loads deadline data' do
      get :show, params: { id: deadline.id }
      expect(assigns(:deadline)).to eq(deadline)
      expect(assigns(:related_documents)).to be_present
      expect(assigns(:activity_log)).to be_present
      expect(assigns(:compliance_status)).to be_present
      expect(assigns(:extensions)).to be_present
    end
  end
  
  describe 'GET #new' do
    before { sign_in juridique_user }
    
    it 'returns success' do
      get :new
      expect(response).to have_http_status(:success)
    end
    
    it 'assigns a new deadline' do
      get :new
      expect(assigns(:deadline)).to be_a_new(LegalDeadline)
    end
    
    it 'pre-fills due date when provided' do
      get :new, params: { due_date: '2024-12-31' }
      expect(assigns(:deadline).due_date).to eq(Date.parse('2024-12-31'))
    end
    
    it 'loads contracts and deadline types' do
      contract # create it
      deadline_type = create(:legal_deadline_type)
      
      get :new
      expect(assigns(:contracts)).to include(contract)
      expect(assigns(:deadline_types)).to include(deadline_type)
    end
  end
  
  describe 'POST #create' do
    before { sign_in juridique_user }
    
    let(:valid_params) do
      {
        legal_deadline: {
          title: 'GDPR Compliance Review',
          description: 'Annual GDPR compliance review',
          due_date: 30.days.from_now,
          priority: 'high',
          responsible_user_id: juridique_user.id
        }
      }
    end
    
    context 'with valid params' do
      it 'creates a new deadline' do
        expect {
          post :create, params: valid_params
        }.to change(LegalDeadline, :count).by(1)
      end
      
      it 'sets created_by' do
        post :create, params: valid_params
        expect(LegalDeadline.last.created_by).to eq(juridique_user)
      end
      
      it 'schedules reminders' do
        expect_any_instance_of(LegalDeadlinesController).to receive(:schedule_reminders)
        post :create, params: valid_params
      end
      
      it 'sends notification' do
        expect_any_instance_of(NotificationService).to receive(:notify_deadline_created)
        post :create, params: valid_params
      end
      
      it 'redirects to deadline' do
        post :create, params: valid_params
        expect(response).to redirect_to(LegalDeadline.last)
        expect(flash[:notice]).to eq('Échéance légale créée avec succès')
      end
    end
    
    context 'with invalid params' do
      it 'does not create deadline' do
        expect {
          post :create, params: { legal_deadline: { title: '' } }
        }.not_to change(LegalDeadline, :count)
      end
      
      it 'renders new template' do
        post :create, params: { legal_deadline: { title: '' } }
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
  
  describe 'PUT #update' do
    before { sign_in juridique_user }
    
    it 'updates deadline' do
      put :update, params: { id: deadline.id, legal_deadline: { title: 'Updated Title' } }
      expect(deadline.reload.title).to eq('Updated Title')
    end
    
    it 'reschedules reminders when due date changes' do
      expect_any_instance_of(LegalDeadlinesController).to receive(:reschedule_reminders)
      put :update, params: { id: deadline.id, legal_deadline: { due_date: 60.days.from_now } }
    end
    
    it 'redirects to deadline' do
      put :update, params: { id: deadline.id, legal_deadline: { title: 'Updated' } }
      expect(response).to redirect_to(deadline)
      expect(flash[:notice]).to eq('Échéance mise à jour avec succès')
    end
  end
  
  describe 'DELETE #destroy' do
    before { sign_in juridique_user }
    
    it 'cancels deadline' do
      expect(deadline).to receive(:cancel!).with(
        reason: 'No longer needed',
        cancelled_by: juridique_user
      )
      delete :destroy, params: { id: deadline.id, reason: 'No longer needed' }
    end
    
    it 'redirects to index' do
      delete :destroy, params: { id: deadline.id }
      expect(response).to redirect_to(legal_deadlines_path)
      expect(flash[:notice]).to eq('Échéance annulée')
    end
  end
  
  describe 'POST #complete' do
    before { sign_in juridique_user }
    
    context 'when deadline can be completed' do
      before { allow(deadline).to receive(:can_be_completed?).and_return(true) }
      
      it 'completes deadline' do
        expect(deadline).to receive(:complete!).with(
          completed_by: juridique_user,
          completion_notes: 'All requirements met',
          supporting_documents: ['1', '2']
        )
        post :complete, params: { 
          id: deadline.id, 
          completion_notes: 'All requirements met',
          document_ids: ['1', '2']
        }
      end
      
      it 'redirects with success' do
        allow(deadline).to receive(:complete!)
        post :complete, params: { id: deadline.id }
        expect(response).to redirect_to(deadline)
        expect(flash[:notice]).to eq('Échéance marquée comme complétée')
      end
    end
    
    context 'when deadline cannot be completed' do
      before { allow(deadline).to receive(:can_be_completed?).and_return(false) }
      
      it 'redirects with error' do
        post :complete, params: { id: deadline.id }
        expect(response).to redirect_to(deadline)
        expect(flash[:alert]).to eq('Cette échéance ne peut pas être complétée')
      end
    end
  end
  
  describe 'POST #extend' do
    before { sign_in juridique_user }
    
    let(:extension_params) do
      {
        id: deadline.id,
        new_due_date: deadline.due_date + 30.days,
        reason: 'Awaiting client response'
      }
    end
    
    it 'creates extension request' do
      expect {
        post :extend, params: extension_params
      }.to change(DeadlineExtension, :count).by(1)
    end
    
    it 'enqueues approval job' do
      expect {
        post :extend, params: extension_params
      }.to have_enqueued_job(DeadlineExtensionApprovalJob)
    end
    
    it 'redirects with notice' do
      post :extend, params: extension_params
      expect(response).to redirect_to(deadline)
      expect(flash[:notice]).to eq('Demande d\'extension envoyée')
    end
  end
  
  describe 'GET #calendar' do
    before { sign_in juridique_user }
    
    it 'returns success' do
      get :calendar
      expect(response).to have_http_status(:success)
    end
    
    it 'supports different view types' do
      get :calendar, params: { view: 'week' }
      expect(assigns(:view_type)).to eq('week')
    end
    
    it 'responds to json' do
      deadline # create it
      get :calendar, format: :json
      json = JSON.parse(response.body)
      expect(json).to include('events', 'statistics')
    end
    
    it 'responds to ics' do
      get :calendar, format: :ics
      expect(response.content_type).to eq('text/calendar')
      expect(response.headers['Content-Disposition']).to include('legal_deadlines.ics')
    end
  end
  
  describe 'GET #dashboard' do
    before { sign_in juridique_user }
    
    it 'returns success' do
      get :dashboard
      expect(response).to have_http_status(:success)
    end
    
    it 'loads dashboard data' do
      get :dashboard
      expect(assigns(:critical_deadlines)).to be_present
      expect(assigns(:overdue_count)).to be_present
      expect(assigns(:this_week_count)).to be_present
      expect(assigns(:compliance_rate)).to be_present
      expect(assigns(:deadline_by_type)).to be_present
      expect(assigns(:responsible_summary)).to be_present
    end
  end
  
  describe 'GET #export' do
    before { sign_in juridique_user }
    
    it 'exports as CSV' do
      get :export, format: :csv
      expect(response.content_type).to eq('text/csv')
      expect(response.headers['Content-Disposition']).to include('legal_deadlines_')
    end
    
    it 'exports as Excel' do
      allow_any_instance_of(LegalDeadlinesController).to receive(:generate_excel).and_return('Excel data')
      get :export, format: :xlsx
      expect(response.content_type).to eq('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
    end
    
    it 'exports as PDF' do
      allow_any_instance_of(LegalDeadlinesController).to receive(:generate_pdf_report).and_return('PDF data')
      get :export, format: :pdf
      expect(response.content_type).to eq('application/pdf')
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