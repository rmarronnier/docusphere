require 'rails_helper'

RSpec.describe Immo::Promo::FinancialDashboard::ProfitabilityTracking, type: :concern do
  let(:controller_class) do
    Class.new do
      include Immo::Promo::FinancialDashboard::ProfitabilityTracking
      
      attr_accessor :project
      
      def initialize(project = nil)
        @project = project
      end
    end
  end
  
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization, project_type: 'residential') }
  let(:controller) { controller_class.new(project) }

  describe '#profitability_analysis' do
    it 'calculates profitability metrics' do
      controller.profitability_analysis
      
      expect(controller.instance_variable_get(:@profitability_data)).to include(
        :total_revenue,
        :total_costs,
        :gross_profit,
        :gross_margin,
        :roi
      )
      
      expect(controller.instance_variable_get(:@margin_analysis)).to be_present
      expect(controller.instance_variable_get(:@revenue_forecast)).to be_present
      expect(controller.instance_variable_get(:@roi_analysis)).to be_present
    end
  end

  describe '#track_project_margins' do
    let!(:lots) do
      create_list(:immo_promo_lot, 3, 
        project: project,
        sale_price_cents: 300000_00,
        construction_cost_cents: 200000_00
      )
    end

    it 'tracks margins by lot and phase' do
      result = controller.track_project_margins
      
      expect(result).to include(
        :overall_margin,
        :margins_by_lot,
        :margins_by_phase,
        :margin_evolution
      )
      
      expect(result[:overall_margin]).to be > 0
    end
  end

  describe '#roi_projections' do
    it 'calculates ROI projections' do
      result = controller.roi_projections
      
      expect(result).to include(
        :current_roi,
        :projected_roi,
        :roi_timeline,
        :sensitivity_analysis
      )
    end
  end

  describe 'private methods' do
    describe '#calculate_lot_margin' do
      let(:lot) do
        create(:immo_promo_lot,
          sale_price_cents: 400000_00,
          construction_cost_cents: 300000_00
        )
      end

      it 'calculates margin for a single lot' do
        margin = controller.send(:calculate_lot_margin, lot)
        
        expect(margin[:amount]).to eq(Money.new(100000_00, 'EUR'))
        expect(margin[:percentage]).to eq(25.0)
      end
    end
  end
end