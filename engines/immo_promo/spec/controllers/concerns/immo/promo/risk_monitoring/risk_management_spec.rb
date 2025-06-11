require 'rails_helper'

RSpec.describe Immo::Promo::RiskMonitoring::RiskManagement, type: :concern do
  
  let(:controller_class) do
    Class.new do
      include Immo::Promo::RiskMonitoring::RiskManagement
      
      attr_accessor :project, :current_user, :params
      
      def initialize(project = nil, user = nil)
        @project = project
        @current_user = user
        @params = {}
      end
      
      def flash
        @flash ||= {}
      end
      
      def redirect_to(path)
        @redirect_path = path
      end
      
      def redirect_back(fallback_location:)
        @redirect_path = fallback_location
      end
      
      def immo_promo_engine
        double('engine', 
          project_risk_monitoring_risk_register_path: '/projects/1/risk_register',
          project_risk_monitoring_dashboard_path: '/projects/1/dashboard'
        )
      end
    end
  end
  
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:controller) { controller_class.new(project, user) }

  describe '#create_risk' do
    let(:risk_params) do
      {
        risk: {
          title: 'Test Risk',
          description: 'Test Description',
          category: 'financial',
          probability: 'medium',
          impact: 'major'
        }
      }
    end

    before do
      controller.params = ActionController::Parameters.new(risk_params)
      allow(controller).to receive(:notify_risk_stakeholders)
    end

    it 'creates a new risk successfully' do
      expect { controller.create_risk }.to change { project.risks.count }.by(1)
      
      risk = project.risks.last
      expect(risk.title).to eq('Test Risk')
      expect(risk.identified_by).to eq(user)
      expect(risk.status).to eq('identified')
    end

    it 'calculates risk score' do
      controller.create_risk
      
      risk = project.risks.last
      expect(risk.risk_score).to eq(12) # medium (3) * major (4)
      expect(risk.severity).to eq('medium')
    end

    it 'creates initial assessment' do
      controller.create_risk
      
      risk = project.risks.last
      expect(risk.risk_assessments.count).to eq(1)
      
      assessment = risk.risk_assessments.first
      expect(assessment.assessed_by).to eq(user)
      expect(assessment.notes).to eq('Évaluation initiale')
    end
  end

  describe '#risk_register' do
    let!(:risk1) { create(:immo_promo_risk, project: project, category: 'financial', severity: 'high') }
    let!(:risk2) { create(:immo_promo_risk, project: project, category: 'technical', severity: 'low') }

    before do
      controller.params = { filters: {} }
    end

    it 'loads project risks with associations' do
      controller.risk_register
      
      expect(controller.instance_variable_get(:@risks)).to include(risk1, risk2)
    end

    it 'groups risks by category, severity, and status' do
      controller.risk_register
      
      risks_by_category = controller.instance_variable_get(:@risks_by_category)
      expect(risks_by_category['financial']).to include(risk1)
      expect(risks_by_category['technical']).to include(risk2)
    end
  end

  describe 'private methods' do
    describe '#calculate_risk_score' do
      let(:risk) { create(:immo_promo_risk, project: project, probability: 'high', impact: 'catastrophic') }

      it 'calculates correct risk score' do
        controller.send(:calculate_risk_score, risk)
        
        expect(risk.risk_score).to eq(20) # high (4) * catastrophic (5)
        expect(risk.severity).to eq('critical')
      end
    end

    describe '#determine_severity' do
      it 'correctly categorizes severity levels' do
        expect(controller.send(:determine_severity, 3)).to eq('low')
        expect(controller.send(:determine_severity, 9)).to eq('medium')
        expect(controller.send(:determine_severity, 15)).to eq('high')
        expect(controller.send(:determine_severity, 25)).to eq('critical')
      end
    end

    describe '#identify_risk_stakeholders' do
      let(:risk_owner) { create(:user, organization: organization) }
      let(:project_manager) { create(:user, organization: organization) }
      let(:risk) { create(:immo_promo_risk, project: project, risk_owner: risk_owner, category: 'financial') }

      before do
        allow(project).to receive(:project_manager).and_return(project_manager)
        allow(project).to receive(:financial_controller).and_return(user)
      end

      it 'identifies relevant stakeholders based on risk category' do
        stakeholders = controller.send(:identify_risk_stakeholders, risk)
        
        expect(stakeholders).to include(risk_owner, project_manager, user)
        expect(stakeholders.uniq.count).to eq(stakeholders.count) # No duplicates
      end
    end

    describe '#detect_emerging_risks' do
      context 'when project has delay risk' do
        before do
          allow(controller).to receive(:project_delay_risk?).and_return(true)
          allow(controller).to receive(:budget_overrun_risk?).and_return(false)
        end

        it 'detects schedule risk' do
          emerging_risks = controller.send(:detect_emerging_risks)
          
          expect(emerging_risks.length).to eq(1)
          expect(emerging_risks.first[:type]).to eq('schedule_risk')
          expect(emerging_risks.first[:title]).to include('retard projet')
        end
      end

      context 'when project has budget risk' do
        before do
          allow(controller).to receive(:project_delay_risk?).and_return(false)
          allow(controller).to receive(:budget_overrun_risk?).and_return(true)
        end

        it 'detects budget risk' do
          emerging_risks = controller.send(:detect_emerging_risks)
          
          expect(emerging_risks.length).to eq(1)
          expect(emerging_risks.first[:type]).to eq('budget_risk')
          expect(emerging_risks.first[:title]).to include('dépassement budgétaire')
        end
      end
    end
  end
end