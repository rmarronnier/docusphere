# frozen_string_literal: true

module Immo
  module Promo
    class ComplianceReportService
      def initialize(project, user)
        @project = project
        @user = user
        @generated_at = Time.current
      end

      # Generate comprehensive compliance report as PDF
      def generate_pdf_report(phase_id: nil, include_recommendations: true)
        report_data = compile_compliance_data(phase_id)
        
        # Use Prawn for PDF generation
        pdf = Prawn::Document.new(page_size: 'A4', margin: 40)
        
        # Header with project info
        add_report_header(pdf)
        
        # Executive summary
        add_executive_summary(pdf, report_data)
        
        # Phase-by-phase compliance
        add_phase_compliance_details(pdf, report_data)
        
        # Document inventory
        add_document_inventory(pdf, report_data)
        
        # Compliance matrix
        add_compliance_matrix(pdf, report_data)
        
        # Risk assessment
        add_risk_assessment(pdf, report_data)
        
        # Recommendations section
        if include_recommendations
          add_recommendations(pdf, report_data)
        end
        
        # Action plan
        add_action_plan(pdf, report_data)
        
        # Appendices
        add_appendices(pdf, report_data)
        
        # Footer with signatures
        add_report_footer(pdf)
        
        pdf.render
      end

      # Generate compliance dashboard data
      def compliance_dashboard_data
        {
          project_overview: project_overview_data,
          compliance_score: calculate_compliance_score,
          phase_status: phases_compliance_status,
          document_status: documents_compliance_status,
          alerts: compliance_alerts,
          timeline: compliance_timeline,
          recommendations: priority_recommendations
        }
      end

      # Generate phase-specific compliance report
      def phase_compliance_report(phase)
        phase_data = {
          phase_info: {
            name: phase.name,
            type: phase.phase_type,
            status: phase.status,
            start_date: phase.start_date,
            end_date: phase.end_date,
            completion_percentage: phase.completion_percentage
          },
          required_documents: required_documents_for_phase(phase),
          submitted_documents: submitted_documents_for_phase(phase),
          missing_documents: missing_documents_for_phase(phase),
          validation_status: validation_status_for_phase(phase),
          compliance_score: calculate_phase_compliance_score(phase),
          risks: identify_phase_risks(phase),
          next_steps: generate_phase_next_steps(phase)
        }

        phase_data
      end

      # Export compliance data to various formats
      def export_compliance_data(format: 'xlsx', include_attachments: false)
        data = compile_compliance_data

        case format.to_s.downcase
        when 'xlsx'
          generate_excel_report(data)
        when 'csv'
          generate_csv_report(data)
        when 'json'
          generate_json_report(data)
        when 'xml'
          generate_xml_report(data)
        else
          raise ArgumentError, "Unsupported export format: #{format}"
        end
      end

      private

      attr_reader :project, :user, :generated_at

      def compile_compliance_data(phase_id = nil)
        phases = phase_id ? [@project.phases.find(phase_id)] : @project.phases.includes(:documents, :phase_dependencies)
        
        {
          project: project_metadata,
          phases: phases.map { |phase| compile_phase_data(phase) },
          overall_compliance: calculate_overall_compliance(phases),
          document_summary: compile_document_summary,
          regulatory_requirements: regulatory_requirements_data,
          timeline: compliance_timeline_data,
          stakeholders: stakeholder_compliance_data,
          recommendations: generate_compliance_recommendations,
          metadata: report_metadata
        }
      end

      def project_metadata
        {
          id: @project.id,
          name: @project.name,
          type: @project.project_type,
          status: @project.status,
          location: project_location_data,
          manager: @project.project_manager&.full_name,
          start_date: @project.start_date,
          expected_completion: @project.expected_completion_date,
          total_budget: @project.total_budget&.amount,
          surface_area: @project.total_surface_area,
          description: @project.description
        }
      end

      def compile_phase_data(phase)
        {
          id: phase.id,
          name: phase.name,
          type: phase.phase_type,
          status: phase.status,
          dates: {
            start: phase.start_date,
            end: phase.end_date,
            actual_start: phase.actual_start_date,
            actual_end: phase.actual_end_date
          },
          completion: phase.completion_percentage,
          documents: {
            required: required_documents_for_phase(phase),
            submitted: submitted_documents_for_phase(phase),
            approved: approved_documents_for_phase(phase),
            missing: missing_documents_for_phase(phase)
          },
          compliance_score: calculate_phase_compliance_score(phase),
          risks: identify_phase_risks(phase),
          dependencies: phase.phase_dependencies.map(&:name),
          validation_status: validation_status_for_phase(phase)
        }
      end

      def calculate_overall_compliance(phases)
        return 0 if phases.empty?

        total_score = phases.sum { |phase| calculate_phase_compliance_score(phase) }
        (total_score.to_f / phases.count).round(2)
      end

      def calculate_phase_compliance_score(phase)
        required_docs = required_documents_for_phase(phase)
        return 100 if required_docs.empty?

        submitted_docs = submitted_documents_for_phase(phase)
        approved_docs = approved_documents_for_phase(phase)

        # Scoring: 50% for submission, 50% for approval
        submission_score = (submitted_docs.count.to_f / required_docs.count) * 50
        approval_score = (approved_docs.count.to_f / required_docs.count) * 50

        (submission_score + approval_score).round(2)
      end

      def required_documents_for_phase(phase)
        case phase.phase_type
        when 'permits'
          %w[permit administrative legal plan environmental]
        when 'studies'
          %w[technical plan project geological environmental]
        when 'construction'
          %w[permit technical plan administrative safety environmental]
        when 'delivery'
          %w[administrative legal technical conformity_certificate]
        else
          %w[project technical administrative]
        end
      end

      def submitted_documents_for_phase(phase)
        phase.documents.group(:document_category).count
      end

      def approved_documents_for_phase(phase)
        phase.documents
             .joins(:validation_requests)
             .where(validation_requests: { status: 'approved' })
             .group(:document_category)
             .count
      end

      def missing_documents_for_phase(phase)
        required = required_documents_for_phase(phase)
        submitted = submitted_documents_for_phase(phase).keys
        required - submitted
      end

      def validation_status_for_phase(phase)
        total_docs = phase.documents.count
        return { status: 'no_documents', message: 'Aucun document soumis' } if total_docs.zero?

        validations = phase.documents.joins(:validation_requests)
        pending = validations.where(validation_requests: { status: 'pending' }).count
        approved = validations.where(validation_requests: { status: 'approved' }).count
        rejected = validations.where(validation_requests: { status: 'rejected' }).count

        if pending > 0
          { status: 'pending', message: "#{pending} validation(s) en attente" }
        elsif rejected > 0
          { status: 'issues', message: "#{rejected} document(s) rejeté(s)" }
        elsif approved == total_docs
          { status: 'complete', message: 'Tous les documents approuvés' }
        else
          { status: 'partial', message: "#{approved}/#{total_docs} documents approuvés" }
        end
      end

      def identify_phase_risks(phase)
        risks = []

        # Deadline risks
        if phase.end_date && phase.end_date < Date.current && phase.status != 'completed'
          days_overdue = (Date.current - phase.end_date).to_i
          risks << {
            type: 'deadline',
            severity: days_overdue > 30 ? 'high' : 'medium',
            description: "Phase en retard de #{days_overdue} jour(s)",
            impact: 'Retard sur le planning global du projet'
          }
        end

        # Document compliance risks
        missing_docs = missing_documents_for_phase(phase)
        if missing_docs.any?
          risks << {
            type: 'documentation',
            severity: missing_docs.count > 2 ? 'high' : 'medium',
            description: "#{missing_docs.count} document(s) manquant(s): #{missing_docs.join(', ')}",
            impact: 'Blocage potentiel pour la suite du projet'
          }
        end

        # Dependency risks
        if phase.phase_dependencies.any? { |dep| dep.status != 'completed' }
          incomplete_deps = phase.phase_dependencies.where.not(status: 'completed')
          risks << {
            type: 'dependency',
            severity: 'high',
            description: "Dépendances non résolues: #{incomplete_deps.pluck(:name).join(', ')}",
            impact: 'Impossible de démarrer cette phase'
          }
        end

        risks
      end

      def generate_phase_next_steps(phase)
        steps = []

        case phase.status
        when 'pending'
          if phase.phase_dependencies.any?
            incomplete_deps = phase.phase_dependencies.where.not(status: 'completed')
            if incomplete_deps.any?
              steps << "Finaliser les dépendances: #{incomplete_deps.pluck(:name).join(', ')}"
            end
          end
          steps << 'Préparer les documents requis pour cette phase'
          steps << 'Planifier les ressources nécessaires'

        when 'in_progress'
          missing_docs = missing_documents_for_phase(phase)
          if missing_docs.any?
            steps << "Soumettre les documents manquants: #{missing_docs.join(', ')}"
          end

          pending_validations = phase.documents.joins(:validation_requests)
                                     .where(validation_requests: { status: 'pending' })
          if pending_validations.any?
            steps << "Suivre #{pending_validations.count} validation(s) en cours"
          end

        when 'completed'
          steps << 'Phase terminée - préparer la phase suivante'
        end

        steps
      end

      def add_report_header(pdf)
        # Logo and header
        pdf.text "RAPPORT DE CONFORMITÉ", size: 24, style: :bold, align: :center
        pdf.move_down 10
        pdf.text "Projet: #{@project.name}", size: 16, style: :bold, align: :center
        pdf.move_down 5
        pdf.text "Généré le #{@generated_at.strftime('%d/%m/%Y à %H:%M')}", size: 10, align: :center
        pdf.move_down 20

        # Project summary table
        project_data = [
          ['Type de projet', @project.project_type.humanize],
          ['Statut', @project.status.humanize],
          ['Chef de projet', @project.project_manager&.full_name || 'Non assigné'],
          ['Date de début', @project.start_date&.strftime('%d/%m/%Y') || 'Non définie'],
          ['Fin prévue', @project.expected_completion_date&.strftime('%d/%m/%Y') || 'Non définie']
        ]

        pdf.table(project_data, width: pdf.bounds.width) do
          row(0..4).borders = [:bottom]
          row(0..4).border_width = 0.5
          column(0).font_style = :bold
          column(0).width = 150
        end

        pdf.move_down 20
      end

      def add_executive_summary(pdf, report_data)
        pdf.text "RÉSUMÉ EXÉCUTIF", size: 16, style: :bold
        pdf.move_down 10

        overall_score = report_data[:overall_compliance]
        
        pdf.text "Score de conformité global: #{overall_score}%", size: 12, style: :bold
        pdf.move_down 5

        status_color = case overall_score
                      when 90..100 then :green
                      when 70..89 then :orange
                      else :red
                      end

        status_text = case overall_score
                     when 90..100 then 'Excellent'
                     when 70..89 then 'Satisfaisant'
                     when 50..69 then 'À améliorer'
                     else 'Critique'
                     end

        pdf.formatted_text [
          { text: "Statut: ", color: '000000' },
          { text: status_text, color: status_color.to_s, style: :bold }
        ]

        pdf.move_down 15

        # Key metrics
        total_phases = report_data[:phases].count
        completed_phases = report_data[:phases].count { |p| p[:status] == 'completed' }
        total_docs = report_data[:document_summary][:total]
        approved_docs = report_data[:document_summary][:approved]

        metrics_data = [
          ['Phases terminées', "#{completed_phases}/#{total_phases}"],
          ['Documents approuvés', "#{approved_docs}/#{total_docs}"],
          ['Alertes actives', report_data[:recommendations].count.to_s]
        ]

        pdf.table(metrics_data, width: 300) do
          column(0).font_style = :bold
        end

        pdf.move_down 20
      end

      # Additional helper methods would continue here...
      # This is a substantial service that would include many more PDF generation methods

      def report_metadata
        {
          generated_at: @generated_at,
          generated_by: @user.full_name,
          report_version: '2.0',
          project_snapshot: {
            phases_count: @project.phases.count,
            documents_count: @project.documents.count,
            last_activity: @project.documents.maximum(:updated_at)
          }
        }
      end
    end
  end
end