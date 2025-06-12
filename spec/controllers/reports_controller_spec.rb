require 'rails_helper'

RSpec.describe ReportsController, type: :controller do
  let(:organization) { create(:organization) }
  let(:admin_user) { create(:user, organization: organization) }
  let(:direction_user) { create(:user, organization: organization) }
  let(:regular_user) { create(:user, organization: organization) }
  let(:report) { create(:report, created_by: direction_user, organization: organization) }
  
  before do
    admin_user.add_role(:admin)
    direction_user.add_role(:direction)
  end
  
  describe 'GET #index' do
    context 'as direction user' do
      before { sign_in direction_user }
      
      it 'returns success' do
        get :index
        expect(response).to have_http_status(:success)
      end
      
      it 'assigns reports' do
        report # create it
        get :index
        expect(assigns(:reports)).to include(report)
      end
      
      it 'assigns report categories' do
        get :index
        expect(assigns(:report_categories)).to be_present
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
    
    context 'as unauthenticated user' do
      it 'redirects to login' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
  
  describe 'GET #show' do
    before { sign_in direction_user }
    
    it 'returns success' do
      get :show, params: { id: report.id }
      expect(response).to have_http_status(:success)
    end
    
    it 'responds to pdf format' do
      allow(report).to receive(:generate_pdf).and_return('PDF content')
      get :show, params: { id: report.id }, format: :pdf
      expect(response.content_type).to eq('application/pdf')
    end
    
    it 'responds to xlsx format' do
      allow(report).to receive(:generate_excel).and_return('Excel content')
      get :show, params: { id: report.id }, format: :xlsx
      expect(response.content_type).to eq('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
    end
  end
  
  describe 'GET #new' do
    before { sign_in direction_user }
    
    it 'returns success' do
      get :new
      expect(response).to have_http_status(:success)
    end
    
    it 'assigns a new report' do
      get :new
      expect(assigns(:report)).to be_a_new(Report)
    end
    
    it 'assigns templates' do
      template = create(:report_template)
      get :new
      expect(assigns(:templates)).to include(template)
    end
  end
  
  describe 'POST #create' do
    before { sign_in direction_user }
    
    let(:valid_params) do
      {
        report: {
          name: 'Monthly Activity Report',
          report_type: 'activity',
          start_date: 1.month.ago,
          end_date: Date.current
        }
      }
    end
    
    context 'with valid params' do
      it 'creates a new report' do
        expect {
          post :create, params: valid_params
        }.to change(Report, :count).by(1)
      end
      
      it 'sets created_by to current user' do
        post :create, params: valid_params
        expect(Report.last.created_by).to eq(direction_user)
      end
      
      it 'enqueues report generation job' do
        expect {
          post :create, params: valid_params
        }.to have_enqueued_job(ReportGenerationJob)
      end
      
      it 'redirects to report' do
        post :create, params: valid_params
        expect(response).to redirect_to(Report.last)
        expect(flash[:notice]).to eq('Rapport en cours de génération...')
      end
    end
    
    context 'with invalid params' do
      it 'does not create report' do
        expect {
          post :create, params: { report: { name: '' } }
        }.not_to change(Report, :count)
      end
      
      it 'renders new template' do
        post :create, params: { report: { name: '' } }
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
  
  describe 'GET #export' do
    before { sign_in direction_user }
    
    it 'exports as PDF by default' do
      allow(report).to receive(:generate_pdf).and_return('PDF content')
      get :export, params: { id: report.id }
      expect(response.content_type).to eq('application/pdf')
    end
    
    it 'exports as Excel when specified' do
      allow(report).to receive(:generate_excel).and_return('Excel content')
      get :export, params: { id: report.id, format_type: 'excel' }
      expect(response.content_type).to eq('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
    end
    
    it 'exports as CSV when specified' do
      allow(report).to receive(:generate_csv).and_return('CSV content')
      get :export, params: { id: report.id, format_type: 'csv' }
      expect(response.content_type).to eq('text/csv')
    end
  end
  
  describe 'authorization' do
    it 'allows admin users' do
      sign_in admin_user
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