require 'rails_helper'

RSpec.describe Immo::Promo::RiskMonitoring::RiskAssessment, type: :concern do
  let(:controller_class) do
    Class.new do
      include Immo::Promo::RiskMonitoring::RiskAssessment
      
      attr_accessor :project, :current_user, :params
      
      def initialize(project = nil, user = nil)
        @project = project
        @current_user = user
        @params = ActionController::Parameters.new
      end
      
      def flash
        @flash ||= {}
      end
      
      def redirect_back(fallback_location:)
        @redirect_path = fallback_location
      end
      
      def immo_promo_engine
        double('engine', project_risk_monitoring_risk_register_path: '/risk_register')
      end
      
      # Mock RiskNotificationService
      class ::RiskNotificationService
        def self.escalate(*args); end
      end
    end
  end
  
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:risk) { create(:immo_promo_risk, project: project, probability: 'medium', impact: 'major') }
  let(:controller) { controller_class.new(project, user) }

  describe '#update_risk_assessment' do
    let(:assessment_params) do
      {
        risk_id: risk.id,
        assessment: {
          probability: 'high',
          impact: 'catastrophic',
          notes: 'Risk has increased',
          reassessment_reason: 'New information available'
        }
      }
    end

    before do
      controller.params = ActionController::Parameters.new(assessment_params)
    end

    it 'creates new risk assessment' do
      expect {
        controller.update_risk_assessment
      }.to change { risk.risk_assessments.count }.by(1)
      
      assessment = risk.risk_assessments.last
      expect(assessment.probability).to eq('high')
      expect(assessment.impact).to eq('catastrophic')
      expect(assessment.assessed_by).to eq(user)
    end

    it 'updates risk score' do
      controller.update_risk_assessment
      
      risk.reload
      expect(risk.risk_score).to eq(20) # high (4) * catastrophic (5)
      expect(risk.severity).to eq('critical')
    end

    it 'triggers escalation for critical risks' do
      expect(RiskNotificationService).to receive(:escalate)
      
      controller.update_risk_assessment
    end
  end

  describe 'private methods' do
    describe '#calculate_risk_exposure' do
      it 'calculates financial exposure based on impact and probability' do
        risk.update(impact: 'major', probability: 'high')
        
        exposure = controller.send(:calculate_risk_exposure, risk)
        
        expect(exposure).to be_a(Money)
        expect(exposure.cents).to eq(350000_00) # 500000 * 0.7
      end
    end

    describe '#analyze_risk_trend' do
      let!(:assessment1) { create(:immo_promo_risk_assessment, risk: risk, probability: 'low', impact: 'minor') }
      let!(:assessment2) { create(:immo_promo_risk_assessment, risk: risk, probability: 'medium', impact: 'moderate') }
      let!(:assessment3) { create(:immo_promo_risk_assessment, risk: risk, probability: 'high', impact: 'major') }

      it 'identifies increasing risk trend' do
        trend = controller.send(:analyze_risk_trend, risk)
        expect(trend).to eq('increasing')
      end
    end

    describe '#determine_escalation_recipients' do
      it 'includes project manager for all escalations' do
        allow(project).to receive(:project_manager).and_return(user)
        
        recipients = controller.send(:determine_escalation_recipients, risk)
        
        expect(recipients).to include(user)
      end

      it 'includes sponsor for critical risks' do
        sponsor = create(:user, organization: organization)
        risk.update(severity: 'critical')
        allow(project).to receive(:project_manager).and_return(user)
        allow(project).to receive(:sponsor).and_return(sponsor)
        
        recipients = controller.send(:determine_escalation_recipients, risk)
        
        expect(recipients).to include(user, sponsor)
      end
    end
  end
end