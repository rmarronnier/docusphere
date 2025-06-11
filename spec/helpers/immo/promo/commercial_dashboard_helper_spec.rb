require 'rails_helper'

RSpec.describe Immo::Promo::CommercialDashboardHelper, type: :helper do
  let(:project) { create(:immo_promo_project) }
  
  describe '#sales_funnel_chart' do
    before do
      project.metadata['sales_data'] = {
        'prospects' => 150,
        'visits' => 80,
        'reservations' => 25,
        'sales' => 20
      }
    end
    
    it 'generates sales funnel visualization' do
      result = helper.sales_funnel_chart(project)
      
      expect(result).to have_css('.sales-funnel')
      expect(result).to have_content('150 prospects')
      expect(result).to have_content('53% conversion') # visits/prospects
      expect(result).to have_content('80 visits')
      expect(result).to have_content('25 reservations')
      expect(result).to have_content('20 sales')
    end
    
    it 'calculates conversion rates between stages' do
      result = helper.sales_funnel_chart(project)
      
      expect(result).to have_css('.conversion-rate', count: 3)
      expect(result).to have_content('13.3% overall conversion')
    end
  end
  
  describe '#lot_availability_summary' do
    before do
      create_list(:immo_promo_lot, 5, project: project, status: 'available')
      create_list(:immo_promo_lot, 3, project: project, status: 'reserved')
      create_list(:immo_promo_lot, 2, project: project, status: 'sold')
    end
    
    it 'displays lot availability breakdown' do
      result = helper.lot_availability_summary(project)
      
      expect(result).to have_content('10 total lots')
      expect(result).to have_css('.available-lots', text: '5')
      expect(result).to have_css('.reserved-lots', text: '3')
      expect(result).to have_css('.sold-lots', text: '2')
    end
    
    it 'shows availability percentage' do
      result = helper.lot_availability_summary(project)
      
      expect(result).to have_content('50% available')
      expect(result).to have_css('.availability-gauge[data-percentage="50"]')
    end
  end
  
  describe '#reservation_timeline' do
    let(:reservations) do
      [
        create(:immo_promo_reservation, created_at: 30.days.ago, status: 'confirmed'),
        create(:immo_promo_reservation, created_at: 20.days.ago, status: 'pending'),
        create(:immo_promo_reservation, created_at: 10.days.ago, status: 'cancelled')
      ]
    end
    
    it 'displays reservation activity timeline' do
      result = helper.reservation_timeline(reservations)
      
      expect(result).to have_css('.timeline-item', count: 3)
      expect(result).to have_css('.status-confirmed')
      expect(result).to have_css('.status-pending')
      expect(result).to have_css('.status-cancelled')
    end
  end
  
  describe '#price_distribution_chart' do
    before do
      create(:immo_promo_lot, project: project, sale_price_cents: 250_000_00)
      create(:immo_promo_lot, project: project, sale_price_cents: 300_000_00)
      create(:immo_promo_lot, project: project, sale_price_cents: 350_000_00)
      create(:immo_promo_lot, project: project, sale_price_cents: 400_000_00)
    end
    
    it 'shows price range distribution' do
      result = helper.price_distribution_chart(project)
      
      expect(result).to have_css('.price-distribution')
      expect(result).to have_content('Min: €250,000')
      expect(result).to have_content('Max: €400,000')
      expect(result).to have_content('Avg: €325,000')
    end
  end
  
  describe '#commercial_kpis' do
    it 'displays key commercial metrics' do
      allow(project).to receive_message_chain(:lots, :count).and_return(50)
      allow(project).to receive_message_chain(:lots, :sold, :count).and_return(15)
      allow(project).to receive_message_chain(:reservations, :pending, :count).and_return(5)
      
      result = helper.commercial_kpis(project)
      
      expect(result).to have_css('.kpi-card', count: 4)
      expect(result).to have_content('Sales Rate: 30%')
      expect(result).to have_content('Pending: 5')
      expect(result).to have_content('Available: 30')
    end
  end
  
  describe '#sales_velocity_indicator' do
    it 'shows sales pace' do
      project.metadata['sales_velocity'] = {
        'current_month' => 5,
        'average_monthly' => 3,
        'target_monthly' => 4
      }
      
      result = helper.sales_velocity_indicator(project)
      
      expect(result).to have_css('.velocity-indicator.above-target')
      expect(result).to have_content('5 sales this month')
      expect(result).to have_content('167% of average')
    end
  end
  
  describe '#prospect_conversion_metrics' do
    it 'displays conversion funnel metrics' do
      metrics = {
        prospects: 100,
        qualified: 60,
        visits: 40,
        offers: 20,
        sales: 15
      }
      
      result = helper.prospect_conversion_metrics(metrics)
      
      expect(result).to have_content('Qualification rate: 60%')
      expect(result).to have_content('Visit conversion: 67%')
      expect(result).to have_content('Offer conversion: 75%')
      expect(result).to have_content('Overall conversion: 15%')
    end
  end
  
  describe '#revenue_forecast' do
    it 'projects revenue based on current performance' do
      project.metadata['revenue_data'] = {
        'realized' => 2_000_000_00,
        'reserved' => 1_500_000_00,
        'projected' => 3_500_000_00
      }
      
      result = helper.revenue_forecast(project)
      
      expect(result).to have_css('.revenue-forecast')
      expect(result).to have_content('Realized: €20,000')
      expect(result).to have_content('Reserved: €15,000')
      expect(result).to have_content('Total projected: €35,000')
    end
  end
end