require 'rails_helper'

RSpec.describe Immo::Promo::CommercialDashboardController, type: :controller do
  routes { ImmoPromo::Engine.routes }
  
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :admin, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }

  before do
    sign_in user
    allow(controller).to receive(:policy_scope).and_return(Immo::Promo::Project.where(id: project.id))
    allow(controller).to receive(:authorize).and_return(true)
  end

  describe 'GET #dashboard' do
    it 'returns a success response' do
      get :dashboard, params: { project_id: project.id }, format: :json
      expect(response).to be_successful
    end

    it 'assigns dashboard data' do
      get :dashboard, params: { project_id: project.id }, format: :json
      expect(assigns(:lots_summary)).to be_present
      expect(assigns(:sales_metrics)).to be_present
      expect(assigns(:reservations_data)).to be_present
      expect(assigns(:revenue_projections)).to be_present
      expect(assigns(:commercial_performance)).to be_present
    end

    it 'responds to JSON format' do
      get :dashboard, params: { project_id: project.id }, format: :json
      expect(response).to be_successful
      expect(response.content_type).to include('application/json')
    end
  end

  describe 'GET #lot_inventory' do
    it 'returns a success response' do
      get :lot_inventory, params: { project_id: project.id }, format: :json
      expect(response).to be_successful
    end

    it 'assigns lots data' do
      get :lot_inventory, params: { project_id: project.id }, format: :json
      expect(assigns(:lots)).to be_present
      expect(assigns(:lots_by_status)).to be_present
      expect(assigns(:lots_by_type)).to be_present
      expect(assigns(:lots_by_floor)).to be_present
    end

    it 'applies filters when provided' do
      get :lot_inventory, params: { 
        project_id: project.id, 
        filters: { status: 'completed', type: 'apartment' }
      }, format: :json
      expect(assigns(:filters)).to eq({ 'status' => 'completed', 'type' => 'apartment' })
    end
  end

  describe 'GET #reservation_management' do
    it 'returns a success response' do
      get :reservation_management, params: { project_id: project.id }, format: :json
      expect(response).to be_successful
    end

    it 'assigns reservation data' do
      get :reservation_management, params: { project_id: project.id }, format: :json
      expect(assigns(:active_reservations)).to be_present
      expect(assigns(:pending_reservations)).to be_present
      expect(assigns(:expired_reservations)).to be_present
      expect(assigns(:reservation_timeline)).to be_present
      expect(assigns(:conversion_metrics)).to be_present
    end
  end

  describe 'GET #pricing_strategy' do
    it 'returns a success response' do
      get :pricing_strategy, params: { project_id: project.id }, format: :json
      expect(response).to be_successful
    end

    it 'assigns pricing analysis data' do
      get :pricing_strategy, params: { project_id: project.id }, format: :json
      expect(assigns(:pricing_analysis)).to be_present
      expect(assigns(:price_recommendations)).to be_present
      expect(assigns(:competitor_analysis)).to be_present
      expect(assigns(:margin_analysis)).to be_present
    end
  end

  describe 'GET #sales_pipeline' do
    it 'returns a success response' do
      get :sales_pipeline, params: { project_id: project.id }, format: :json
      expect(response).to be_successful
    end

    it 'assigns pipeline data' do
      get :sales_pipeline, params: { project_id: project.id }, format: :json
      expect(assigns(:pipeline_stages)).to be_present
      expect(assigns(:prospects)).to be_present
      expect(assigns(:conversion_funnel)).to be_present
      expect(assigns(:sales_velocity)).to be_present
      expect(assigns(:bottlenecks)).to be_present
    end
  end

  describe 'GET #customer_insights' do
    it 'returns a success response' do
      get :customer_insights, params: { project_id: project.id }, format: :json
      expect(response).to be_successful
    end

    it 'assigns customer analysis data' do
      get :customer_insights, params: { project_id: project.id }, format: :json
      expect(assigns(:customer_segments)).to be_present
      expect(assigns(:buyer_preferences)).to be_present
      expect(assigns(:satisfaction_metrics)).to be_present
      expect(assigns(:referral_tracking)).to be_present
    end
  end

  describe 'POST #create_reservation' do
    let(:lot) { create(:immo_promo_lot, project: project) }
    let(:valid_reservation_params) do
      {
        client_name: 'John Doe',
        client_email: 'john@example.com',
        client_phone: '+33123456789',
        reservation_amount: '5000',
        validity_days: '15',
        notes: 'Test reservation'
      }
    end

    it 'creates a reservation when lot is available' do
      allow_any_instance_of(Immo::Promo::Lot).to receive(:is_available?).and_return(true)
      
      post :create_reservation, params: {
        project_id: project.id,
        lot_id: lot.id,
        reservation: valid_reservation_params
      }
      
      expect(response).to redirect_to("/immo/promo/projects/#{project.id}/commercial_dashboard/reservation_management")
      expect(flash[:success]).to be_present
    end

    it 'shows error when lot is not available' do
      allow_any_instance_of(Immo::Promo::Lot).to receive(:is_available?).and_return(false)
      
      post :create_reservation, params: {
        project_id: project.id,
        lot_id: lot.id,
        reservation: valid_reservation_params
      }
      
      expect(flash[:error]).to be_present
    end
  end

  describe 'PATCH #update_lot_status' do
    let(:lot) { create(:immo_promo_lot, project: project, status: 'completed') }

    it 'updates lot status when transition is valid' do
      allow(controller).to receive(:valid_status_transition?).and_return(true)
      
      patch :update_lot_status, params: {
        project_id: project.id,
        lot_id: lot.id,
        status: 'reserved'
      }
      
      expect(flash[:success]).to be_present
    end

    it 'shows error when transition is invalid' do
      allow(controller).to receive(:valid_status_transition?).and_return(false)
      
      patch :update_lot_status, params: {
        project_id: project.id,
        lot_id: lot.id,
        status: 'sold'
      }
      
      expect(flash[:error]).to be_present
    end
  end

  describe 'GET #generate_offer' do
    let(:lot) { create(:immo_promo_lot, project: project) }
    let(:reservation) { create(:immo_promo_reservation, lot: lot) }

    it 'generates PDF offer' do
      get :generate_offer, params: {
        project_id: project.id,
        lot_id: lot.id,
        reservation_id: reservation.id
      }, format: :pdf
      
      expect(response).to be_successful
      expect(response.content_type).to include('application/pdf')
    end
  end

  describe 'GET #export_inventory' do
    it 'exports inventory as XLSX' do
      get :export_inventory, params: { project_id: project.id }, format: :xlsx
      expect(response).to be_successful
    end

    it 'exports inventory as CSV' do
      get :export_inventory, params: { project_id: project.id }, format: :csv
      expect(response).to be_successful
      expect(response.content_type).to include('text/csv')
    end
  end

  describe 'GET #sales_report' do
    it 'generates sales report PDF' do
      get :sales_report, params: { project_id: project.id }, format: :pdf
      expect(response).to be_successful
      expect(response.content_type).to include('application/pdf')
    end
  end

  describe 'authorization' do
    it 'authorizes commercial access' do
      expect(controller).to receive(:authorize).with(project, :manage_commercial?).and_return(true)
      get :dashboard, params: { project_id: project.id }, format: :json
    end
  end

  describe 'private methods' do
    it 'responds to calculate_lots_summary' do
      expect(controller).to respond_to(:calculate_lots_summary, true)
    end

    it 'responds to calculate_sales_metrics' do
      expect(controller).to respond_to(:calculate_sales_metrics, true)
    end

    it 'responds to valid_status_transition?' do
      expect(controller).to respond_to(:valid_status_transition?, true)
    end
  end
end