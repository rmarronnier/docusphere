module Immo
  module Promo
    module PermitWorkflow
      module DocumentGeneration
        extend ActiveSupport::Concern

        def generate_submission_package
          @permit = @project.permits.find(params[:permit_id])
          
          package_data = compile_submission_package(@permit)
          
          respond_to do |format|
            format.pdf do
              render pdf: "dossier_#{@permit.permit_type}_#{@project.reference_number}",
                     layout: 'pdf',
                     template: 'immo/promo/permit_workflow/submission_package_pdf',
                     locals: { package_data: package_data }
            end
            format.zip do
              zip_file = generate_submission_zip(@permit, package_data)
              send_file zip_file, filename: "dossier_#{@permit.permit_type}_#{@project.reference_number}.zip"
            end
          end
        end

        def export_report
          @permit_tracker = PermitTrackerService.new(@project, current_user)
          @report_data = @permit_tracker.generate_permit_report
          
          respond_to do |format|
            format.pdf do
              render pdf: "rapport_permis_#{@project.reference_number}",
                     layout: 'pdf',
                     template: 'immo/promo/permit_workflow/report_pdf'
            end
            format.xlsx do
              render xlsx: 'report_xlsx',
                     filename: "rapport_permis_#{@project.reference_number}.xlsx"
            end
          end
        end

        private

        def compile_submission_package(permit)
          # Compile le dossier de soumission
          {
            permit: permit,
            required_documents: get_required_documents_for_permit(permit),
            forms: get_required_forms_for_permit(permit),
            studies: get_required_studies_for_permit(permit)
          }
        end

        def get_required_documents_for_permit(permit)
          case permit.permit_type
          when 'construction'
            %w[plans_masse plans_facades plans_coupes notice_architecturale]
          when 'urban_planning'
            %w[plan_situation plan_masse notice_urbanisme]
          else
            %w[plans_masse]
          end
        end

        def get_required_forms_for_permit(permit)
          case permit.permit_type
          when 'construction'
            %w[cerfa_13406 attestation_rt2012]
          when 'urban_planning'
            %w[cerfa_13703]
          else
            []
          end
        end

        def get_required_studies_for_permit(permit)
          case permit.permit_type
          when 'construction'
            %w[etude_sol etude_thermique]
          when 'environmental_impact'
            %w[etude_impact notice_incidences]
          else
            []
          end
        end

        def generate_submission_zip(permit, package_data)
          # Génère un fichier ZIP avec tous les documents
          # Implémentation simulée
          temp_file = Tempfile.new(['submission', '.zip'])
          temp_file.path
        end
      end
    end
  end
end