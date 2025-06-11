require 'rails_helper'

RSpec.describe Immo::Promo::RiskMonitoring::AlertManagement, type: :concern do
  let(:controller_class) do
    Class.new do
      include Immo::Promo::RiskMonitoring::AlertManagement
      include Immo::Promo::RiskMonitoring::MitigationManagement # For find_overdue_mitigation_actions
      include Immo::Promo::RiskMonitoring::RiskManagement # For detect_emerging_risks
      
      attr_accessor :project, :current_user, :params, :active_risks
      
      def initialize(project = nil, user = nil)
        @project = project
        @current_user = user
        @params = ActionController::Parameters.new
        @active_risks = []
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
        double('engine', project_risk_monitoring_alert_center_path: '/alert_center')
      end
      
      # Mock Alert model
      class ::Alert
        attr_accessor :id
        
        def self.find(id)
          alert = new
          alert.id = id
          alert
        end
        
        def acknowledge!(user)
          true
        end
      end
      
      # Mock AlertConfiguration
      class ::AlertConfiguration
        def self.find_or_initialize_by(attrs)
          new
        end
        
        def attributes=(attrs); end
        def configured_by=(user); end
        def save; true; end
      end
    end
  end
  
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:controller) { controller_class.new(project, user) }

  describe '#alert_center' do
    it 'initializes alert service and loads alert data' do
      controller.alert_center
      
      expect(controller.instance_variable_get(:@alert_service)).not_to be_nil
      expect(controller.instance_variable_get(:@active_alerts)).to eq([])
      expect(controller.instance_variable_get(:@alert_history)).to eq([])
      expect(controller.instance_variable_get(:@alert_configurations)).to eq([])
      expect(controller.instance_variable_get(:@notification_channels)).to eq(%w[email sms dashboard push_notification])
    end
  end

  describe '#early_warning_system' do
    it 'initializes warning service and calculates indicators' do
      controller.early_warning_system
      
      expect(controller.instance_variable_get(:@warning_service)).not_to be_nil
      expect(controller.instance_variable_get(:@warning_indicators)).to eq({})
      expect(controller.instance_variable_get(:@trend_analysis)).to eq({})
      expect(controller.instance_variable_get(:@predictive_alerts)).to eq([])
      expect(controller.instance_variable_get(:@threshold_violations)).to eq([])
    end
  end

  describe '#configure_alert' do
    let(:alert_params) do
      {
        alert: {
          alert_type: 'risk_score_threshold',
          threshold_value: 15,
          comparison_operator: 'greater_than',
          notification_channels: ['email', 'dashboard'],
          recipients: [user.id],
          active: true
        }
      }
    end

    before do
      controller.params = ActionController::Parameters.new(alert_params)
    end

    it 'creates or updates alert configuration' do
      controller.configure_alert
      
      expect(controller.flash[:success]).to eq("Configuration d'alerte enregistrée")
    end
  end

  describe '#acknowledge_alert' do
    let(:alert_id) { 123 }

    before do
      controller.params = ActionController::Parameters.new(alert_id: alert_id)
    end

    it 'acknowledges the alert' do
      controller.acknowledge_alert
      
      expect(controller.flash[:success]).to eq('Alerte acquittée')
    end
  end

  describe 'private methods' do
    describe '#generate_risk_alerts' do
      context 'with critical risks' do
        before do
          controller.active_risks = [
            { severity: 'critical' },
            { severity: 'critical' },
            { severity: 'high' }
          ]
        end

        it 'generates alert for critical risks' do
          alerts = controller.send(:generate_risk_alerts)
          
          critical_alert = alerts.find { |a| a[:type] == 'critical_risks' }
          expect(critical_alert).not_to be_nil
          expect(critical_alert[:severity]).to eq('critical')
          expect(critical_alert[:title]).to include('2 risques critiques')
        end
      end

      context 'with overdue mitigation actions' do
        let(:overdue_action) { double('MitigationAction') }
        
        before do
          allow(controller).to receive(:find_overdue_mitigation_actions).and_return([overdue_action])
        end

        it 'generates alert for overdue actions' do
          alerts = controller.send(:generate_risk_alerts)
          
          overdue_alert = alerts.find { |a| a[:type] == 'overdue_mitigations' }
          expect(overdue_alert).not_to be_nil
          expect(overdue_alert[:severity]).to eq('high')
        end
      end
    end
  end
end