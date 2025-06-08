module Immo
  module Promo
    class RiskMonitoringController < Immo::Promo::ApplicationController
      before_action :set_project
      before_action :authorize_risk_management

      def dashboard
        @risk_service = ProjectRiskService.new(@project)
        @risk_overview = @risk_service.risk_overview
        @active_risks = @risk_service.active_risks
        @risk_matrix = @risk_service.generate_risk_matrix
        @mitigation_status = @risk_service.mitigation_tracking
        @alerts = generate_risk_alerts
        
        respond_to do |format|
          format.html
          format.json { render json: risk_dashboard_data }
        end
      end

      def risk_register
        @risks = @project.risks.includes(:mitigation_actions, :risk_assessments)
        @filters = params[:filters] || {}
        
        apply_risk_filters if @filters.any?
        
        @risks_by_category = @risks.group_by(&:category)
        @risks_by_severity = @risks.group_by(&:severity)
        @risks_by_status = @risks.group_by(&:status)
      end

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

      def create_risk
        risk_params = params.require(:risk).permit(
          :title, :description, :category, :probability, :impact,
          :risk_owner_id, :detection_date, :target_resolution_date
        )
        
        @risk = @project.risks.build(risk_params)
        @risk.identified_by = current_user
        @risk.status = 'identified'
        
        if @risk.save
          calculate_risk_score(@risk)
          create_initial_assessment(@risk)
          notify_risk_stakeholders(@risk)
          
          flash[:success] = "Risque identifié et enregistré"
          redirect_to immo_promo_engine.project_risk_monitoring_risk_register_path(@project)
        else
          flash[:error] = @risk.errors.full_messages.join(', ')
          redirect_back(fallback_location: immo_promo_engine.project_risk_monitoring_dashboard_path(@project))
        end
      end

      def update_risk_assessment
        @risk = @project.risks.find(params[:risk_id])
        assessment_params = params.require(:assessment).permit(
          :probability, :impact, :notes, :reassessment_reason
        )
        
        assessment = create_risk_assessment(@risk, assessment_params)
        
        if assessment[:success]
          update_risk_score(@risk)
          check_risk_escalation(@risk)
          
          flash[:success] = "Évaluation du risque mise à jour"
        else
          flash[:error] = assessment[:error]
        end
        
        redirect_back(fallback_location: immo_promo_engine.project_risk_monitoring_risk_register_path(@project))
      end

      def create_mitigation_action
        @risk = @project.risks.find(params[:risk_id])
        action_params = params.require(:action).permit(
          :action_type, :description, :responsible_id, :due_date,
          :cost_estimate, :effectiveness_estimate
        )
        
        action = @risk.mitigation_actions.build(action_params)
        action.created_by = current_user
        
        if action.save
          update_risk_mitigation_status(@risk)
          schedule_mitigation_reminders(action)
          
          flash[:success] = "Action d'atténuation créée"
        else
          flash[:error] = action.errors.full_messages.join(', ')
        end
        
        redirect_to immo_promo_engine.project_risk_monitoring_risk_register_path(@project)
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

      def risk_report
        @risk_service = ProjectRiskService.new(@project)
        @report_data = compile_risk_report
        
        respond_to do |format|
          format.pdf do
            render pdf: "rapport_risques_#{@project.reference_number}",
                   layout: 'pdf',
                   template: 'immo/promo/risk_monitoring/risk_report_pdf'
          end
          format.xlsx do
            render xlsx: 'risk_report_xlsx',
                   filename: "rapport_risques_#{@project.reference_number}.xlsx"
          end
        end
      end

      def risk_matrix_export
        @risk_service = ProjectRiskService.new(@project)
        @matrix_data = @risk_service.generate_detailed_risk_matrix
        
        respond_to do |format|
          format.json { render json: @matrix_data }
          format.svg { render_risk_matrix_svg }
        end
      end

      private

      def set_project
        @project = policy_scope(Project).find(params[:project_id])
      end

      def authorize_risk_management
        authorize @project, :manage_risks?
      end

      def risk_dashboard_data
        {
          project: {
            id: @project.id,
            name: @project.name,
            reference: @project.reference_number
          },
          risk_overview: @risk_overview,
          active_risks: @active_risks,
          risk_matrix: @risk_matrix,
          mitigation_status: @mitigation_status,
          alerts: @alerts
        }
      end

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

      def apply_risk_filters
        @risks = @risks.where(category: @filters[:category]) if @filters[:category].present?
        @risks = @risks.where(severity: @filters[:severity]) if @filters[:severity].present?
        @risks = @risks.where(status: @filters[:status]) if @filters[:status].present?
        @risks = @risks.where(risk_owner_id: @filters[:owner]) if @filters[:owner].present?
        
        if @filters[:probability].present?
          @risks = @risks.where(probability: @filters[:probability])
        end
        
        if @filters[:impact].present?
          @risks = @risks.where(impact: @filters[:impact])
        end
      end

      def calculate_risk_score(risk)
        probability_scores = { 'very_low' => 1, 'low' => 2, 'medium' => 3, 'high' => 4, 'very_high' => 5 }
        impact_scores = { 'negligible' => 1, 'minor' => 2, 'moderate' => 3, 'major' => 4, 'catastrophic' => 5 }
        
        prob_score = probability_scores[risk.probability] || 3
        impact_score = impact_scores[risk.impact] || 3
        
        risk.risk_score = prob_score * impact_score
        risk.severity = determine_severity(risk.risk_score)
        risk.save
      end

      def determine_severity(score)
        case score
        when 1..6
          'low'
        when 7..12
          'medium'
        when 13..19
          'high'
        else
          'critical'
        end
      end

      def create_initial_assessment(risk)
        assessment = risk.risk_assessments.create(
          assessed_by: current_user,
          probability: risk.probability,
          impact: risk.impact,
          assessment_date: Date.current,
          notes: "Évaluation initiale"
        )
      end

      def notify_risk_stakeholders(risk)
        stakeholders = identify_risk_stakeholders(risk)
        
        stakeholders.each do |stakeholder|
          RiskNotificationService.notify(
            stakeholder,
            "Nouveau risque identifié: #{risk.title}",
            risk
          )
        end
      end

      def identify_risk_stakeholders(risk)
        stakeholders = [risk.risk_owner]
        stakeholders << @project.project_manager
        
        # Ajouter les parties prenantes selon la catégorie du risque
        case risk.category
        when 'financial'
          stakeholders << @project.financial_controller
        when 'technical'
          stakeholders << @project.technical_manager
        when 'regulatory'
          stakeholders << @project.compliance_officer
        end
        
        stakeholders.compact.uniq
      end

      def create_risk_assessment(risk, params)
        assessment = risk.risk_assessments.build(
          assessed_by: current_user,
          probability: params[:probability],
          impact: params[:impact],
          assessment_date: Date.current,
          notes: params[:notes],
          reassessment_reason: params[:reassessment_reason]
        )
        
        if assessment.save
          { success: true, assessment: assessment }
        else
          { success: false, error: assessment.errors.full_messages.join(', ') }
        end
      end

      def update_risk_score(risk)
        calculate_risk_score(risk)
      end

      def check_risk_escalation(risk)
        previous_severity = risk.severity_was
        
        if risk.severity != previous_severity && ['high', 'critical'].include?(risk.severity)
          escalate_risk(risk, previous_severity)
        end
      end

      def escalate_risk(risk, previous_severity)
        # Notifier la hiérarchie
        escalation_recipients = determine_escalation_recipients(risk)
        
        escalation_recipients.each do |recipient|
          RiskNotificationService.escalate(
            recipient,
            "Escalade risque: #{risk.title}",
            risk,
            previous_severity
          )
        end
        
        # Créer une entrée d'escalade
        risk.escalations.create(
          escalated_by: current_user,
          escalated_at: Time.current,
          from_severity: previous_severity,
          to_severity: risk.severity,
          reason: "Réévaluation du risque"
        )
      end

      def determine_escalation_recipients(risk)
        recipients = [@project.project_manager]
        
        if risk.severity == 'critical'
          recipients << @project.sponsor
          recipients << @project.executive_committee
        end
        
        recipients.flatten.compact.uniq
      end

      def update_risk_mitigation_status(risk)
        active_mitigations = risk.mitigation_actions.where(status: ['planned', 'in_progress']).count
        completed_mitigations = risk.mitigation_actions.where(status: 'completed').count
        
        if completed_mitigations > 0 && active_mitigations == 0
          risk.update(mitigation_status: 'mitigated')
        elsif active_mitigations > 0
          risk.update(mitigation_status: 'mitigation_in_progress')
        else
          risk.update(mitigation_status: 'unmitigated')
        end
      end

      def schedule_mitigation_reminders(action)
        # Planifier des rappels pour l'action d'atténuation
        if action.due_date
          ReminderService.schedule(
            action.responsible,
            action,
            action.due_date - 7.days,
            "Rappel: Action d'atténuation à venir"
          )
          
          ReminderService.schedule(
            action.responsible,
            action,
            action.due_date - 1.day,
            "Urgent: Action d'atténuation due demain"
          )
        end
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

      def find_overdue_mitigation_actions
        MitigationAction.joins(:risk)
                       .where(risks: { project_id: @project.id })
                       .where(status: ['planned', 'in_progress'])
                       .where('due_date < ?', Date.current)
      end

      def detect_emerging_risks
        # Détection des risques émergents basée sur les indicateurs
        emerging = []
        
        # Exemple: Risques liés aux retards
        if project_delay_risk?
          emerging << {
            type: 'schedule_risk',
            title: 'Risque de retard projet',
            indicators: ['Retard sur jalons critiques', 'Tâches en retard > 15%'],
            recommended_action: 'Réviser le planning et identifier les causes'
          }
        end
        
        # Exemple: Risques budgétaires
        if budget_overrun_risk?
          emerging << {
            type: 'budget_risk',
            title: 'Risque de dépassement budgétaire',
            indicators: ['Consommation > 90% avec 70% d\'avancement', 'Tendance défavorable'],
            recommended_action: 'Analyser les écarts et mettre en place des mesures de contrôle'
          }
        end
        
        emerging
      end

      def project_delay_risk?
        # Logique simplifiée de détection de risque de retard
        overdue_tasks = @project.tasks.where('due_date < ? AND status != ?', Date.current, 'completed').count
        total_tasks = @project.tasks.count
        
        return false if total_tasks.zero?
        
        (overdue_tasks.to_f / total_tasks) > 0.15
      end

      def budget_overrun_risk?
        # Logique simplifiée de détection de risque budgétaire
        return false unless @project.total_budget && @project.current_budget
        
        budget_usage = @project.budget_usage_percentage
        project_progress = @project.calculate_overall_progress
        
        budget_usage > 90 && project_progress < 70
      end

      def compile_risk_report
        {
          project: @project,
          report_date: Date.current,
          executive_summary: generate_executive_summary,
          risk_overview: @risk_service.risk_overview,
          risk_matrix: @risk_service.generate_detailed_risk_matrix,
          active_risks: compile_active_risks_details,
          mitigation_status: @risk_service.detailed_mitigation_status,
          trend_analysis: @risk_service.risk_trend_analysis,
          recommendations: generate_risk_recommendations,
          generated_by: current_user
        }
      end

      def generate_executive_summary
        total_risks = @project.risks.count
        critical_risks = @project.risks.where(severity: 'critical').count
        high_risks = @project.risks.where(severity: 'high').count
        
        {
          total_risks: total_risks,
          critical_risks: critical_risks,
          high_risks: high_risks,
          overall_risk_level: determine_overall_risk_level,
          key_concerns: identify_key_concerns,
          mitigation_effectiveness: calculate_mitigation_effectiveness
        }
      end

      def determine_overall_risk_level
        critical_count = @project.risks.where(severity: 'critical', status: 'active').count
        high_count = @project.risks.where(severity: 'high', status: 'active').count
        
        if critical_count > 0
          'critical'
        elsif high_count > 3
          'high'
        elsif high_count > 0
          'medium'
        else
          'low'
        end
      end

      def identify_key_concerns
        concerns = []
        
        # Risques critiques non atténués
        unmitigated_critical = @project.risks.where(
          severity: 'critical',
          mitigation_status: 'unmitigated'
        )
        
        if unmitigated_critical.any?
          concerns << "#{unmitigated_critical.count} risques critiques sans plan d'atténuation"
        end
        
        # Actions en retard
        overdue_actions = find_overdue_mitigation_actions
        if overdue_actions.count > 5
          concerns << "#{overdue_actions.count} actions d'atténuation en retard"
        end
        
        concerns
      end

      def calculate_mitigation_effectiveness
        total_mitigated = @project.risks.where(mitigation_status: 'mitigated').count
        total_with_plan = @project.risks.where.not(mitigation_status: 'unmitigated').count
        
        return 0 if total_with_plan.zero?
        
        (total_mitigated.to_f / total_with_plan * 100).round(1)
      end

      def compile_active_risks_details
        @project.risks.active.includes(:risk_owner, :mitigation_actions).map do |risk|
          {
            risk: risk,
            assessments: risk.risk_assessments.order(assessment_date: :desc).limit(3),
            mitigation_actions: risk.mitigation_actions,
            exposure: calculate_risk_exposure(risk),
            trend: analyze_risk_trend(risk)
          }
        end
      end

      def calculate_risk_exposure(risk)
        # Calcul de l'exposition au risque (impact financier potentiel)
        base_exposure = case risk.impact
        when 'catastrophic' then 1_000_000
        when 'major' then 500_000
        when 'moderate' then 100_000
        when 'minor' then 25_000
        else 5_000
        end
        
        probability_factor = case risk.probability
        when 'very_high' then 0.9
        when 'high' then 0.7
        when 'medium' then 0.5
        when 'low' then 0.3
        else 0.1
        end
        
        Money.new((base_exposure * probability_factor).to_i, 'EUR')
      end

      def analyze_risk_trend(risk)
        recent_assessments = risk.risk_assessments.order(assessment_date: :desc).limit(3)
        
        return 'stable' if recent_assessments.count < 2
        
        scores = recent_assessments.map { |a| calculate_assessment_score(a) }
        
        if scores.first > scores.last
          'increasing'
        elsif scores.first < scores.last
          'decreasing'
        else
          'stable'
        end
      end

      def calculate_assessment_score(assessment)
        probability_scores = { 'very_low' => 1, 'low' => 2, 'medium' => 3, 'high' => 4, 'very_high' => 5 }
        impact_scores = { 'negligible' => 1, 'minor' => 2, 'moderate' => 3, 'major' => 4, 'catastrophic' => 5 }
        
        prob_score = probability_scores[assessment.probability] || 3
        impact_score = impact_scores[assessment.impact] || 3
        
        prob_score * impact_score
      end

      def generate_risk_recommendations
        recommendations = []
        
        # Recommandations pour risques critiques
        critical_risks = @project.risks.where(severity: 'critical', status: 'active')
        if critical_risks.any?
          recommendations << {
            priority: 'urgent',
            category: 'risk_mitigation',
            recommendation: 'Développer des plans d\'atténuation immédiats pour tous les risques critiques',
            affected_risks: critical_risks.pluck(:id)
          }
        end
        
        # Recommandations pour améliorer le monitoring
        if @project.risks.count > 20 && !automated_monitoring_enabled?
          recommendations << {
            priority: 'high',
            category: 'process_improvement',
            recommendation: 'Mettre en place un système de monitoring automatisé des risques',
            benefits: ['Détection précoce', 'Alertes en temps réel', 'Réduction charge administrative']
          }
        end
        
        recommendations
      end

      def automated_monitoring_enabled?
        # Vérifier si le monitoring automatisé est activé
        AlertConfiguration.where(project: @project, active: true).exists?
      end

      def render_risk_matrix_svg
        # Génération d'une matrice de risques en SVG
        # Implémentation simplifiée
        render plain: generate_svg_matrix, content_type: 'image/svg+xml'
      end

      def generate_svg_matrix
        # Code SVG simplifié pour la matrice
        <<~SVG
          <svg width="500" height="500" xmlns="http://www.w3.org/2000/svg">
            <!-- Matrice de risques 5x5 -->
            <!-- Implémentation détaillée ici -->
          </svg>
        SVG
      end

      # Classes de service simulées
      class ProjectRiskService
        def initialize(project)
          @project = project
        end

        def risk_overview
          {
            total_risks: @project.risks.count,
            by_severity: @project.risks.group(:severity).count,
            by_status: @project.risks.group(:status).count,
            by_category: @project.risks.group(:category).count
          }
        end

        def active_risks
          @project.risks.where(status: 'active').includes(:risk_owner)
        end

        def generate_risk_matrix
          # Génération de la matrice de risques
          matrix = {}
          
          %w[very_low low medium high very_high].each do |probability|
            matrix[probability] = {}
            %w[negligible minor moderate major catastrophic].each do |impact|
              matrix[probability][impact] = @project.risks.where(
                probability: probability,
                impact: impact,
                status: 'active'
              ).count
            end
          end
          
          matrix
        end

        def mitigation_tracking
          {
            total_actions: @project.risks.joins(:mitigation_actions).count,
            completed: @project.risks.joins(:mitigation_actions)
                              .where(mitigation_actions: { status: 'completed' }).count,
            in_progress: @project.risks.joins(:mitigation_actions)
                                .where(mitigation_actions: { status: 'in_progress' }).count,
            overdue: @project.risks.joins(:mitigation_actions)
                            .where(mitigation_actions: { status: ['planned', 'in_progress'] })
                            .where('mitigation_actions.due_date < ?', Date.current).count
          }
        end

        def generate_detailed_risk_matrix
          # Version détaillée pour export
          generate_risk_matrix
        end

        def detailed_mitigation_status
          # Statut détaillé des atténuations
          mitigation_tracking
        end

        def risk_trend_analysis
          # Analyse des tendances
          {
            new_risks_30d: @project.risks.where('created_at > ?', 30.days.ago).count,
            closed_risks_30d: @project.risks.where(status: 'closed')
                                     .where('updated_at > ?', 30.days.ago).count,
            severity_changes: track_severity_changes
          }
        end

        private

        def track_severity_changes
          # Suivi des changements de sévérité
          []
        end
      end

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