module Immo
  module Promo
    module RiskMonitoring
      module ReportGeneration
        extend ActiveSupport::Concern

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

        # Classe de service pour les rapports de risques
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
      end
    end
  end
end