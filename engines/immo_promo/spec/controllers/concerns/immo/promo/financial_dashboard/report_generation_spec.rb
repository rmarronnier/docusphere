require 'rails_helper'

RSpec.describe Immo::Promo::FinancialDashboard::ReportGeneration, type: :concern do
  let(:controller_class) do
    Class.new do
      include Immo::Promo::FinancialDashboard::ReportGeneration
      
      attr_accessor :project, :current_user, :params
      
      def initialize(project = nil, user = nil)
        @project = project
        @current_user = user
        @params = ActionController::Parameters.new
      end
      
      def render(*args)
        @rendered = args
      end
      
      def send_data(data, options = {})
        @sent_data = { data: data, options: options }
      end
      
      def flash
        @flash ||= {}
      end
      
      def redirect_back(fallback_location:)
        @redirect_path = fallback_location
      end
      
      def redirect_to(path)
        @redirect_path = path
      end
      
      def respond_to
        yield self
      end
      
      def format
        self
      end
      
      def pdf(&block)
        @pdf_block = block
        block.call if block_given?
      end
      
      def xlsx(&block)
        @xlsx_block = block
        block.call if block_given?
      end
      
      def immo_promo_engine
        double('engine', project_financial_dashboard_path: '/financial_dashboard')
      end
    end
  end
  
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:controller) { controller_class.new(project, user) }

  describe '#generate_financial_report' do
    let(:budget_service) { double('ProjectBudgetService') }
    
    before do
      allow(Immo::Promo::ProjectBudgetService).to receive(:new).and_return(budget_service)
      allow(budget_service).to receive(:budget_summary).and_return({})
      allow(controller).to receive(:compile_comprehensive_financial_report).and_return({
        executive_summary: {},
        financial_overview: {},
        budget_analysis: {}
      })
    end

    it 'generates financial report in PDF format' do
      controller.params = ActionController::Parameters.new(format: :pdf)
      
      controller.generate_financial_report
      
      expect(controller.instance_variable_get(:@pdf_block)).not_to be_nil
      expect(controller.instance_variable_get(:@rendered)).to include(
        pdf: "rapport_financier_#{project.reference_number}"
      )
    end

    it 'generates financial report in XLSX format' do
      controller.params = ActionController::Parameters.new(format: :xlsx)
      
      controller.generate_financial_report
      
      expect(controller.instance_variable_get(:@xlsx_block)).not_to be_nil
    end
  end

  describe '#export_budget_data' do
    let(:budget_service) { double('ProjectBudgetService') }
    
    before do
      allow(Immo::Promo::ProjectBudgetService).to receive(:new).and_return(budget_service)
      allow(budget_service).to receive(:budget_summary).and_return({
        total_budget: Money.new(1000000, 'EUR'),
        spent_amount: Money.new(600000, 'EUR')
      })
      allow(budget_service).to receive(:detailed_budget_breakdown).and_return([])
    end

    context 'CSV export' do
      it 'exports budget data as CSV' do
        controller.params = ActionController::Parameters.new(format: 'csv')
        
        controller.export_budget_data
        
        expect(controller.instance_variable_get(:@sent_data)).not_to be_nil
        expect(controller.instance_variable_get(:@sent_data)[:options][:filename]).to include('.csv')
      end
    end

    context 'JSON export' do
      it 'exports budget data as JSON' do
        controller.params = ActionController::Parameters.new(format: 'json')
        
        controller.export_budget_data
        
        expect(controller.instance_variable_get(:@sent_data)).not_to be_nil
        expect(controller.instance_variable_get(:@sent_data)[:options][:type]).to eq('application/json')
      end
    end
  end

  describe '#sync_accounting_system' do
    it 'synchronizes with external accounting system' do
      allow(controller).to receive(:synchronize_with_accounting).and_return({
        success: true,
        updated_records: 42
      })
      
      controller.sync_accounting_system
      
      expect(controller.flash[:success]).to eq('Synchronisation comptable réussie')
      expect(controller.flash[:info]).to include('42')
    end

    it 'handles synchronization errors' do
      allow(controller).to receive(:synchronize_with_accounting).and_return({
        success: false,
        error: 'Connection timeout'
      })
      
      controller.sync_accounting_system
      
      expect(controller.flash[:error]).to include('Connection timeout')
    end
  end
end