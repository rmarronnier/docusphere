require 'rails_helper'

RSpec.describe Immo::Promo::RiskMonitoring::MitigationManagement, type: :concern do
  let(:controller_class) do
    Class.new do
      include Immo::Promo::RiskMonitoring::MitigationManagement
      include Immo::Promo::RiskMonitoring::RiskAssessment # For calculate_risk_exposure and analyze_risk_trend
      
      attr_accessor :project, :current_user, :params
      
      def initialize(project = nil, user = nil)
        @project = project
        @current_user = user
        @params = ActionController::Parameters.new
      end
      
      def flash
        @flash ||= {}
      end
      
      def redirect_to(path)
        @redirect_path = path
      end
      
      def immo_promo_engine
        double('engine', project_risk_monitoring_risk_register_path: '/risk_register')
      end
      
      # Mock ReminderService
      class ::ReminderService
        def self.schedule(*args); end
      end
      
      # Mock AlertConfiguration
      class ::AlertConfiguration
        def self.where(*args)
          double(exists?: false)
        end
      end
    end
  end
  
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:risk) { create(:immo_promo_risk, project: project) }
  let(:controller) { controller_class.new(project, user) }

  describe '#create_mitigation_action' do
    let(:action_params) do
      {
        risk_id: risk.id,
        action: {
          action_type: 'preventive',
          description: 'Implement safety protocols',
          responsible_id: user.id,
          due_date: 1.month.from_now,
          cost_estimate: 5000,
          effectiveness_estimate: 80
        }
      }
    end

    before do
      controller.params = ActionController::Parameters.new(action_params)
    end

    it 'creates mitigation action for the risk' do
      expect {
        controller.create_mitigation_action
      }.to change { risk.mitigation_actions.count }.by(1)
      
      action = risk.mitigation_actions.last
      expect(action.action_type).to eq('preventive')
      expect(action.created_by).to eq(user)
    end

    it 'updates risk mitigation status' do
      controller.create_mitigation_action
      
      risk.reload
      expect(risk.mitigation_status).to eq('mitigation_in_progress')
    end

    it 'schedules mitigation reminders' do
      expect(ReminderService).to receive(:schedule).twice
      
      controller.create_mitigation_action
    end
  end

  describe 'private methods' do
    describe '#find_overdue_mitigation_actions' do
      let!(:overdue_action) do
        create(:immo_promo_mitigation_action,
          risk: risk,
          status: 'in_progress',
          due_date: 1.week.ago
        )
      end
      
      let!(:on_time_action) do
        create(:immo_promo_mitigation_action,
          risk: risk,
          status: 'in_progress',
          due_date: 1.week.from_now
        )
      end

      it 'finds overdue mitigation actions' do
        overdue = controller.send(:find_overdue_mitigation_actions)
        
        expect(overdue).to include(overdue_action)
        expect(overdue).not_to include(on_time_action)
      end
    end

    describe '#calculate_mitigation_effectiveness' do
      let!(:risk1) { create(:immo_promo_risk, project: project, mitigation_status: 'mitigated') }
      let!(:risk2) { create(:immo_promo_risk, project: project, mitigation_status: 'mitigation_in_progress') }
      let!(:risk3) { create(:immo_promo_risk, project: project, mitigation_status: 'unmitigated') }

      it 'calculates overall mitigation effectiveness' do
        effectiveness = controller.send(:calculate_mitigation_effectiveness)
        
        expect(effectiveness).to eq(50.0) # 1 mitigated out of 2 with plans
      end
    end

    describe '#generate_risk_recommendations' do
      context 'with critical risks' do
        let!(:critical_risk) { create(:immo_promo_risk, project: project, severity: 'critical', status: 'active') }

        it 'recommends immediate mitigation plans' do
          recommendations = controller.send(:generate_risk_recommendations)
          
          expect(recommendations).to be_an(Array)
          expect(recommendations.first[:priority]).to eq('urgent')
          expect(recommendations.first[:category]).to eq('risk_mitigation')
        end
      end

      context 'with many risks and no monitoring' do
        before do
          create_list(:immo_promo_risk, 25, project: project)
        end

        it 'recommends automated monitoring' do
          recommendations = controller.send(:generate_risk_recommendations)
          
          monitoring_rec = recommendations.find { |r| r[:category] == 'process_improvement' }
          expect(monitoring_rec).not_to be_nil
          expect(monitoring_rec[:priority]).to eq('high')
        end
      end
    end
  end
end