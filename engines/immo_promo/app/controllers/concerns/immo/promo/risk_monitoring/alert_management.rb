module Immo
  module Promo
    module RiskMonitoring
      module AlertManagement
        extend ActiveSupport::Concern

        def alert_center
          @alert_service = AlertService.new(@project)
          @active_alerts = @alert_service.active_alerts
          @alert_history = @alert_service.alert_history(limit: 50)
          @alert_configurations = @alert_service.configurations
          @notification_channels = @alert_service.available_channels
        end

        def early_warning_system
          @warning_service = EarlyWarningService.new(@project)
          @warning_indicators = @warning_service.calculate_indicators
          @trend_analysis = @warning_service.analyze_trends
          @predictive_alerts = @warning_service.generate_predictive_alerts
          @threshold_violations = @warning_service.check_thresholds
        end

        def configure_alert
          alert_params = params.require(:alert).permit(
            :alert_type, :threshold_value, :comparison_operator,
            :notification_channels, :recipients, :active
          )
          
          alert_config = create_or_update_alert_configuration(alert_params)
          
          if alert_config[:success]
            flash[:success] = "Configuration d'alerte enregistrée"
          else
            flash[:error] = alert_config[:error]
          end
          
          redirect_to immo_promo_engine.project_risk_monitoring_alert_center_path(@project)
        end

        def acknowledge_alert
          @alert = Alert.find(params[:alert_id])
          
          if @alert.acknowledge!(current_user)
            flash[:success] = "Alerte acquittée"
          else
            flash[:error] = "Impossible d'acquitter l'alerte"
          end
          
          redirect_back(fallback_location: immo_promo_engine.project_risk_monitoring_alert_center_path(@project))
        end

        private

        def generate_risk_alerts
          alerts = []
          
          # Alertes pour risques critiques
          critical_risks = @active_risks.select { |r| r[:severity] == 'critical' }
          if critical_risks.any?
            alerts << {
              type: 'critical_risks',
              severity: 'critical',
              title: "#{critical_risks.count} risques critiques actifs",
              description: "Action immédiate requise",
              risks: critical_risks
            }
          end
          
          # Alertes pour actions en retard
          overdue_actions = find_overdue_mitigation_actions
          if overdue_actions.any?
            alerts << {
              type: 'overdue_mitigations',
              severity: 'high',
              title: "#{overdue_actions.count} actions d'atténuation en retard",
              description: "Suivi urgent nécessaire",
              actions: overdue_actions
            }
          end
          
          # Alertes pour risques émergents
          emerging_risks = detect_emerging_risks
          if emerging_risks.any?
            alerts << {
              type: 'emerging_risks',
              severity: 'medium',
              title: "#{emerging_risks.count} risques émergents détectés",
              description: "Évaluation recommandée",
              risks: emerging_risks
            }
          end
          
          alerts
        end

        def create_or_update_alert_configuration(params)
          config = AlertConfiguration.find_or_initialize_by(
            project: @project,
            alert_type: params[:alert_type]
          )
          
          config.attributes = params
          config.configured_by = current_user
          
          if config.save
            { success: true, configuration: config }
          else
            { success: false, error: config.errors.full_messages.join(', ') }
          end
        end

        # Classes de service pour les alertes
        class AlertService
          def initialize(project)
            @project = project
          end

          def active_alerts
            []
          end

          def alert_history(limit: 50)
            []
          end

          def configurations
            []
          end

          def available_channels
            %w[email sms dashboard push_notification]
          end
        end

        class EarlyWarningService
          def initialize(project)
            @project = project
          end

          def calculate_indicators
            {}
          end

          def analyze_trends
            {}
          end

          def generate_predictive_alerts
            []
          end

          def check_thresholds
            []
          end
        end
      end
    end
  end
end