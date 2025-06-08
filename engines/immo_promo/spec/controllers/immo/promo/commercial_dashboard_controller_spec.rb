require 'rails_helper'

RSpec.describe Immo::Promo::CommercialDashboardController, type: :controller do
  routes { ImmoPromo::Engine.routes }
  
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:project) { 
    create(:immo_promo_project, 
      organization: organization, 
      project_manager: user,
      units_count: 50
    ) 
  }
  
  before do
    sign_in user
    allow(controller).to receive(:current_organization).and_return(organization)
  end

  describe 'GET #dashboard' do
    let!(:lots) { create_list(:immo_promo_lot, 20, project: project) }
    let!(:reservations) { 
      lots.first(5).map do |lot|
        create(:immo_promo_reservation, lot: lot, status: 'active')
      end
    }

    it 'returns http success' do
      get :dashboard, params: { project_id: project.id }
      expect(response).to have_http_status(:success)
    end

    it 'loads commercial overview' do
      get :dashboard, params: { project_id: project.id }
      
      overview = assigns(:commercial_overview)
      expect(overview).to be_present
      expect(overview).to include(
        :total_lots,
        :available,
        :reserved,
        :sold,
        :revenue_potential
      )
    end

    it 'calculates sales velocity' do
      get :dashboard, params: { project_id: project.id }
      
      sales_velocity = assigns(:sales_velocity)
      expect(sales_velocity).to be_present
      expect(sales_velocity).to include(:current_month, :average, :trend)
    end

    it 'loads performance indicators' do
      get :dashboard, params: { project_id: project.id }
      
      expect(assigns(:conversion_rate)).to be_present
      expect(assigns(:average_price_sqm)).to be_present
    end
  end

  describe 'GET #lot_inventory' do
    let!(:lots) do
      [
        create(:immo_promo_lot, project: project, lot_type: 'T2', floor: 1, status: 'available'),
        create(:immo_promo_lot, project: project, lot_type: 'T3', floor: 2, status: 'reserved'),
        create(:immo_promo_lot, project: project, lot_type: 'T4', floor: 3, status: 'sold'),
        create(:immo_promo_lot, project: project, lot_type: 'T2', floor: 0, status: 'available')
      ]
    end

    it 'returns http success' do
      get :lot_inventory, params: { project_id: project.id }
      expect(response).to have_http_status(:success)
    end

    it 'filters lots by status' do
      get :lot_inventory, params: { 
        project_id: project.id,
        filters: { status: 'available' }
      }
      
      filtered_lots = assigns(:lots)
      expect(filtered_lots.count).to eq(2)
      expect(filtered_lots.pluck(:status).uniq).to eq(['available'])
    end

    it 'filters lots by type' do
      get :lot_inventory, params: {
        project_id: project.id,
        filters: { lot_type: 'T2' }
      }
      
      filtered_lots = assigns(:lots)
      expect(filtered_lots.count).to eq(2)
      expect(filtered_lots.pluck(:lot_type).uniq).to eq(['T2'])
    end

    it 'filters lots by floor' do
      get :lot_inventory, params: {
        project_id: project.id,
        filters: { floor: '0,1' }
      }
      
      filtered_lots = assigns(:lots)
      expect(filtered_lots.count).to eq(2)
    end

    it 'sorts lots' do
      get :lot_inventory, params: {
        project_id: project.id,
        sort: 'price_desc'
      }
      
      expect(assigns(:lots)).to be_present
    end
  end

  describe 'GET #reservation_management' do
    let!(:lots) { create_list(:immo_promo_lot, 10, project: project) }
    let!(:reservations) do
      [
        create(:immo_promo_reservation, lot: lots[0], status: 'active', created_at: 1.week.ago),
        create(:immo_promo_reservation, lot: lots[1], status: 'pending', created_at: 2.days.ago),
        create(:immo_promo_reservation, lot: lots[2], status: 'converted', created_at: 1.month.ago),
        create(:immo_promo_reservation, lot: lots[3], status: 'cancelled', created_at: 3.weeks.ago)
      ]
    end

    it 'returns http success' do
      get :reservation_management, params: { project_id: project.id }
      expect(response).to have_http_status(:success)
    end

    it 'loads reservations pipeline' do
      get :reservation_management, params: { project_id: project.id }
      
      pipeline = assigns(:reservation_pipeline)
      expect(pipeline).to be_present
      expect(pipeline).to include(:pending, :active, :expiring_soon)
    end

    it 'calculates conversion metrics' do
      get :reservation_management, params: { project_id: project.id }
      
      conversion_metrics = assigns(:conversion_metrics)
      expect(conversion_metrics).to include(
        :conversion_rate,
        :average_time_to_convert,
        :cancellation_rate
      )
    end

    it 'identifies expiring reservations' do
      get :reservation_management, params: { project_id: project.id }
      
      expiring = assigns(:expiring_reservations)
      expect(expiring).to be_present
    end
  end

  describe 'GET #pricing_strategy' do
    let!(:lots) { create_list(:immo_promo_lot, 20, project: project) }

    it 'returns http success' do
      get :pricing_strategy, params: { project_id: project.id }
      expect(response).to have_http_status(:success)
    end

    it 'analyzes pricing by lot type' do
      get :pricing_strategy, params: { project_id: project.id }
      
      pricing_analysis = assigns(:pricing_analysis)
      expect(pricing_analysis).to be_present
      expect(pricing_analysis).to include(:by_type, :by_floor, :by_orientation)
    end

    it 'provides market comparison' do
      get :pricing_strategy, params: { project_id: project.id }
      
      market_comparison = assigns(:market_comparison)
      expect(market_comparison).to be_present
      expect(market_comparison).to include(:average_market_price, :positioning)
    end

    it 'suggests pricing optimizations' do
      get :pricing_strategy, params: { project_id: project.id }
      
      suggestions = assigns(:pricing_suggestions)
      expect(suggestions).to be_present
    end
  end

  describe 'GET #sales_pipeline' do
    let!(:lots) { create_list(:immo_promo_lot, 15, project: project) }
    let!(:reservations) { create_list(:immo_promo_reservation, 8, lot: lots.sample) }

    it 'returns http success' do
      get :sales_pipeline, params: { project_id: project.id }
      expect(response).to have_http_status(:success)
    end

    it 'shows pipeline stages' do
      get :sales_pipeline, params: { project_id: project.id }
      
      pipeline = assigns(:sales_pipeline)
      expect(pipeline).to include(
        :prospects,
        :visits,
        :reservations,
        :contracts,
        :deliveries
      )
    end

    it 'calculates pipeline value' do
      get :sales_pipeline, params: { project_id: project.id }
      
      pipeline_value = assigns(:pipeline_value)
      expect(pipeline_value).to be_present
      expect(pipeline_value).to include(:total, :weighted, :by_stage)
    end

    it 'provides sales forecast' do
      get :sales_pipeline, params: { project_id: project.id }
      
      forecast = assigns(:sales_forecast)
      expect(forecast).to be_present
      expect(forecast).to include(:next_month, :next_quarter, :year_end)
    end
  end

  describe 'GET #customer_insights' do
    let!(:lots) { create_list(:immo_promo_lot, 10, project: project) }
    let!(:reservations) { create_list(:immo_promo_reservation, 5, lot: lots.sample) }

    it 'returns http success' do
      get :customer_insights, params: { project_id: project.id }
      expect(response).to have_http_status(:success)
    end

    it 'analyzes customer segments' do
      get :customer_insights, params: { project_id: project.id }
      
      segments = assigns(:customer_segments)
      expect(segments).to be_present
      expect(segments).to include(:investors, :first_time_buyers, :families)
    end

    it 'provides preference analysis' do
      get :customer_insights, params: { project_id: project.id }
      
      preferences = assigns(:customer_preferences)
      expect(preferences).to include(
        :preferred_lot_types,
        :preferred_floors,
        :price_sensitivity
      )
    end
  end

  describe 'POST #create_reservation' do
    let(:lot) { create(:immo_promo_lot, project: project, status: 'available') }

    context 'with valid data' do
      it 'creates reservation successfully' do
        post :create_reservation, params: {
          project_id: project.id,
          lot_id: lot.id,
          reservation: {
            client_name: 'John Doe',
            client_email: 'john@example.com',
            client_phone: '0123456789',
            deposit_amount_cents: 5000_00,
            expiry_date: 30.days.from_now
          }
        }
        
        expect(response).to redirect_to(immo_promo_engine.project_commercial_reservation_management_path(project))
        expect(lot.reload.status).to eq('reserved')
        expect(flash[:success]).to be_present
      end
    end

    context 'when lot is already reserved' do
      before { lot.update(status: 'reserved') }

      it 'prevents double reservation' do
        post :create_reservation, params: {
          project_id: project.id,
          lot_id: lot.id,
          reservation: {
            client_name: 'Jane Doe',
            client_email: 'jane@example.com'
          }
        }
        
        expect(response).to redirect_to(immo_promo_engine.project_commercial_lot_inventory_path(project))
        expect(flash[:error]).to match(/déjà réservé/)
      end
    end
  end

  describe 'PATCH #update_lot_status' do
    let(:lot) { create(:immo_promo_lot, project: project, status: 'reserved') }
    let(:reservation) { create(:immo_promo_reservation, lot: lot, status: 'active') }

    it 'updates lot status to sold' do
      patch :update_lot_status, params: {
        project_id: project.id,
        lot_id: lot.id,
        status_update: {
          status: 'sold',
          sale_price_cents: lot.base_price_cents,
          sale_date: Date.current,
          buyer_name: reservation.client_name
        }
      }
      
      expect(response).to redirect_to(immo_promo_engine.project_commercial_lot_inventory_path(project))
      expect(lot.reload.status).to eq('sold')
      expect(reservation.reload.status).to eq('converted')
    end
  end

  describe 'GET #generate_offer' do
    let(:lot) { create(:immo_promo_lot, project: project) }
    let(:reservation) { create(:immo_promo_reservation, lot: lot) }

    it 'generates offer document' do
      get :generate_offer, params: {
        project_id: project.id,
        lot_id: lot.id,
        format: :pdf
      }
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/pdf')
      expect(response.headers['Content-Disposition']).to match(/offre_commerciale/)
    end
  end

  describe 'GET #export_inventory' do
    let!(:lots) { create_list(:immo_promo_lot, 15, project: project) }

    it 'exports inventory as Excel' do
      get :export_inventory, params: {
        project_id: project.id,
        format: :xlsx
      }
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to match(/spreadsheetml/)
    end

    it 'exports inventory as CSV' do
      get :export_inventory, params: {
        project_id: project.id,
        format: :csv
      }
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('text/csv')
    end
  end

  describe 'GET #sales_report' do
    let!(:lots) { create_list(:immo_promo_lot, 20, project: project) }

    it 'generates comprehensive sales report' do
      get :sales_report, params: {
        project_id: project.id,
        format: :pdf,
        period: 'current_month'
      }
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/pdf')
    end

    it 'includes all report sections' do
      get :sales_report, params: {
        project_id: project.id,
        format: :pdf
      }
      
      report_data = assigns(:report_data)
      expect(report_data[:sections]).to include(
        :executive_summary,
        :sales_performance,
        :inventory_status,
        :revenue_analysis,
        :customer_insights
      )
    end
  end

  describe 'JSON API responses' do
    it 'returns commercial overview as JSON' do
      get :dashboard, params: { project_id: project.id }, format: :json
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to include('commercial_overview', 'sales_velocity', 'conversion_rate')
    end

    it 'returns lot inventory as JSON' do
      create_list(:immo_promo_lot, 5, project: project)
      
      get :lot_inventory, params: { project_id: project.id }, format: :json
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to include('lots', 'summary', 'filters')
    end
  end
end