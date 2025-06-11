require 'rails_helper'

RSpec.describe Immo::Promo::RiskMonitoring::ReportGeneration, type: :concern do
  let(:controller_class) do
    Class.new do
      include Immo::Promo::RiskMonitoring::ReportGeneration
      include Immo::Promo::RiskMonitoring::MitigationManagement # For helper methods
      
      attr_accessor :project, :current_user, :params
      
      def initialize(project = nil, user = nil)
        @project = project
        @current_user = user
        @params = ActionController::Parameters.new
      end
      
      def render(*args)
        @rendered = args
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
      
      def json(&block)
        @json_block = block
        @json_response = nil
        self
      end
      
      def svg(&block)
        @svg_block = block
        block.call if block_given?
      end
      
      def render(options)
        if options[:json]
          @json_response = options[:json]
        elsif options[:plain]
          @svg_response = options[:plain]
        else
          @rendered = options
        end
      end
    end
  end
  
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:controller) { controller_class.new(project, user) }

  describe '#risk_report' do
    let(:risk_service) { double('ProjectRiskService') }
    
    before do
      allow(controller.class::ProjectRiskService).to receive(:new).and_return(risk_service)
      allow(risk_service).to receive(:risk_overview).and_return({})
      allow(risk_service).to receive(:generate_detailed_risk_matrix).and_return({})
      allow(risk_service).to receive(:detailed_mitigation_status).and_return({})
      allow(risk_service).to receive(:risk_trend_analysis).and_return({})
      allow(controller).to receive(:compile_risk_report).and_return({
        project: project,
        report_date: Date.current,
        executive_summary: {}
      })
    end

    it 'generates risk report in PDF format' do
      controller.params = ActionController::Parameters.new(format: :pdf)
      
      controller.risk_report
      
      expect(controller.instance_variable_get(:@pdf_block)).not_to be_nil
      expect(controller.instance_variable_get(:@rendered)).to include(
        pdf: "rapport_risques_#{project.reference_number}"
      )
    end

    it 'generates risk report in XLSX format' do
      controller.params = ActionController::Parameters.new(format: :xlsx)
      
      controller.risk_report
      
      expect(controller.instance_variable_get(:@xlsx_block)).not_to be_nil
    end
  end

  describe '#risk_matrix_export' do
    let(:risk_service) { double('ProjectRiskService') }
    let(:matrix_data) { { 'high' => { 'major' => 2 } } }
    
    before do
      allow(controller.class::ProjectRiskService).to receive(:new).and_return(risk_service)
      allow(risk_service).to receive(:generate_detailed_risk_matrix).and_return(matrix_data)
    end

    it 'exports risk matrix as JSON' do
      controller.params = ActionController::Parameters.new(format: :json)
      
      controller.risk_matrix_export
      
      expect(controller.instance_variable_get(:@json_response)).to eq(matrix_data)
    end

    it 'exports risk matrix as SVG' do
      controller.params = ActionController::Parameters.new(format: :svg)
      
      controller.risk_matrix_export
      
      expect(controller.instance_variable_get(:@svg_response)).to include('<svg')
    end
  end

  describe 'private methods' do
    describe '#generate_executive_summary' do
      let!(:risks) { create_list(:immo_promo_risk, 5, project: project) }
      let!(:critical_risk) { create(:immo_promo_risk, project: project, severity: 'critical') }
      let!(:high_risks) { create_list(:immo_promo_risk, 2, project: project, severity: 'high') }

      it 'generates comprehensive executive summary' do
        summary = controller.send(:generate_executive_summary)
        
        expect(summary).to include(
          total_risks: 8,
          critical_risks: 1,
          high_risks: 2,
          overall_risk_level: 'critical',
          key_concerns: be_an(Array),
          mitigation_effectiveness: be_a(Numeric)
        )
      end
    end

    describe '#determine_overall_risk_level' do
      context 'with critical risks' do
        let!(:critical_risk) { create(:immo_promo_risk, project: project, severity: 'critical', status: 'active') }

        it 'returns critical level' do
          level = controller.send(:determine_overall_risk_level)
          expect(level).to eq('critical')
        end
      end

      context 'with multiple high risks' do
        let!(:high_risks) { create_list(:immo_promo_risk, 4, project: project, severity: 'high', status: 'active') }

        it 'returns high level' do
          level = controller.send(:determine_overall_risk_level)
          expect(level).to eq('high')
        end
      end
    end
  end
end