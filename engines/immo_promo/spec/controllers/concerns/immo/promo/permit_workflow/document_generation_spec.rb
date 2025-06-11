require 'rails_helper'

RSpec.describe Immo::Promo::PermitWorkflow::DocumentGeneration, type: :concern do

  let(:controller_class) do
    Class.new(ApplicationController) do
      include Immo::Promo::PermitWorkflow::DocumentGeneration
      
      attr_accessor :project, :params, :rendered_template, :rendered_format, :sent_file
      
      def initialize(project = nil)
        @project = project
        @params = {}
        @rendered_template = nil
        @rendered_format = nil
        @sent_file = nil
      end
      
      def respond_to
        yield MockFormatHandler.new(self)
      end
      
      def render(options)
        @rendered_format = determine_format_from_options(options)
        @rendered_template = options[:template] || options[:xlsx]
        @rendered_options = options
      end
      
      def send_file(file_path, options = {})
        @sent_file = { path: file_path, options: options }
      end
      
      private
      
      def determine_format_from_options(options)
        return :pdf if options[:pdf]
        return :xlsx if options[:xlsx]
        :html
      end
    end
  end
  
  class MockFormatHandler
    def initialize(controller)
      @controller = controller
    end
    
    def pdf(&block)
      block.call if block_given?
    end
    
    def xlsx(&block)
      block.call if block_given?
    end
    
    def zip(&block)
      block.call if block_given?
    end
  end
  
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization, reference_number: 'PRJ-2025-001') }
  let(:permit) { create(:immo_promo_permit, project: project, permit_type: 'construction') }
  let(:controller) { controller_class.new(project) }

  before do
    controller.params = { permit_id: permit.id }
  end

  describe '#generate_submission_package' do
    context 'for PDF format' do
      it 'generates PDF submission package' do
        allow(controller).to receive(:compile_submission_package).and_return({
          permit: permit,
          required_documents: %w[plans_masse plans_facades],
          forms: %w[cerfa_13406],
          studies: %w[etude_sol]
        })
        
        controller.generate_submission_package
        
        expect(controller.rendered_format).to eq(:pdf)
        expect(controller.rendered_template).to eq('immo/promo/permit_workflow/submission_package_pdf')
      end
    end

    context 'for ZIP format' do
      it 'generates ZIP submission package' do
        temp_file_path = '/tmp/submission.zip'
        allow(controller).to receive(:compile_submission_package).and_return({})
        allow(controller).to receive(:generate_submission_zip).and_return(temp_file_path)
        
        controller.generate_submission_package
        
        expect(controller.sent_file[:path]).to eq(temp_file_path)
        expect(controller.sent_file[:options][:filename]).to eq('dossier_construction_PRJ-2025-001.zip')
      end
    end
  end

  describe '#export_report' do
    let(:permit_tracker_service) { instance_double('PermitTrackerService') }
    let(:report_data) { { permits: [], compliance: {} } }

    before do
      allow(PermitTrackerService).to receive(:new).and_return(permit_tracker_service)
      allow(permit_tracker_service).to receive(:generate_permit_report).and_return(report_data)
    end

    context 'for PDF format' do
      it 'exports PDF report' do
        controller.export_report
        
        expect(controller.rendered_format).to eq(:pdf)
        expect(controller.rendered_template).to eq('immo/promo/permit_workflow/report_pdf')
      end
    end

    context 'for XLSX format' do
      it 'exports XLSX report' do
        controller.export_report
        
        expect(controller.rendered_format).to eq(:xlsx)
        expect(controller.rendered_template).to eq('report_xlsx')
      end
    end
  end

  describe '#compile_submission_package' do
    it 'compiles complete submission package' do
      package = controller.send(:compile_submission_package, permit)
      
      expect(package[:permit]).to eq(permit)
      expect(package[:required_documents]).to be_an(Array)
      expect(package[:forms]).to be_an(Array)
      expect(package[:studies]).to be_an(Array)
    end
  end

  describe '#get_required_documents_for_permit' do
    context 'for construction permit' do
      let(:construction_permit) { create(:immo_promo_permit, permit_type: 'construction') }

      it 'returns construction-specific documents' do
        documents = controller.send(:get_required_documents_for_permit, construction_permit)
        
        expect(documents).to eq(%w[plans_masse plans_facades plans_coupes notice_architecturale])
      end
    end

    context 'for urban planning permit' do
      let(:urban_permit) { create(:immo_promo_permit, permit_type: 'urban_planning') }

      it 'returns urban planning documents' do
        documents = controller.send(:get_required_documents_for_permit, urban_permit)
        
        expect(documents).to eq(%w[plan_situation plan_masse notice_urbanisme])
      end
    end

    context 'for other permit types' do
      let(:other_permit) { create(:immo_promo_permit, permit_type: 'other_type') }

      it 'returns basic documents' do
        documents = controller.send(:get_required_documents_for_permit, other_permit)
        
        expect(documents).to eq(%w[plans_masse])
      end
    end
  end

  describe '#get_required_forms_for_permit' do
    context 'for construction permit' do
      let(:construction_permit) { create(:immo_promo_permit, permit_type: 'construction') }

      it 'returns construction-specific forms' do
        forms = controller.send(:get_required_forms_for_permit, construction_permit)
        
        expect(forms).to eq(%w[cerfa_13406 attestation_rt2012])
      end
    end

    context 'for urban planning permit' do
      let(:urban_permit) { create(:immo_promo_permit, permit_type: 'urban_planning') }

      it 'returns urban planning forms' do
        forms = controller.send(:get_required_forms_for_permit, urban_permit)
        
        expect(forms).to eq(%w[cerfa_13703])
      end
    end

    context 'for other permit types' do
      let(:other_permit) { create(:immo_promo_permit, permit_type: 'other_type') }

      it 'returns no specific forms' do
        forms = controller.send(:get_required_forms_for_permit, other_permit)
        
        expect(forms).to eq([])
      end
    end
  end

  describe '#get_required_studies_for_permit' do
    context 'for construction permit' do
      let(:construction_permit) { create(:immo_promo_permit, permit_type: 'construction') }

      it 'returns construction-specific studies' do
        studies = controller.send(:get_required_studies_for_permit, construction_permit)
        
        expect(studies).to eq(%w[etude_sol etude_thermique])
      end
    end

    context 'for environmental impact permit' do
      let(:env_permit) { create(:immo_promo_permit, permit_type: 'environmental_impact') }

      it 'returns environmental studies' do
        studies = controller.send(:get_required_studies_for_permit, env_permit)
        
        expect(studies).to eq(%w[etude_impact notice_incidences])
      end
    end

    context 'for other permit types' do
      let(:other_permit) { create(:immo_promo_permit, permit_type: 'other_type') }

      it 'returns no specific studies' do
        studies = controller.send(:get_required_studies_for_permit, other_permit)
        
        expect(studies).to eq([])
      end
    end
  end

  describe '#generate_submission_zip' do
    it 'generates a temporary ZIP file' do
      package_data = { permit: permit, required_documents: [], forms: [], studies: [] }
      
      zip_path = controller.send(:generate_submission_zip, permit, package_data)
      
      expect(zip_path).to be_a(String)
      expect(zip_path).to include('.zip')
    end
  end

  describe 'document requirements by permit type' do
    it 'provides comprehensive document mapping' do
      # Test multiple permit types to ensure consistency
      permit_types = %w[construction urban_planning environmental_impact]
      
      permit_types.each do |permit_type|
        test_permit = create(:immo_promo_permit, permit_type: permit_type)
        
        documents = controller.send(:get_required_documents_for_permit, test_permit)
        forms = controller.send(:get_required_forms_for_permit, test_permit)
        studies = controller.send(:get_required_studies_for_permit, test_permit)
        
        # All should return arrays
        expect(documents).to be_an(Array)
        expect(forms).to be_an(Array)
        expect(studies).to be_an(Array)
        
        # Documents should always include at least basic requirements
        expect(documents).not_to be_empty if %w[construction urban_planning].include?(permit_type)
      end
    end
  end

  describe 'file naming conventions' do
    it 'generates consistent file names' do
      # Test different permit types
      %w[construction urban_planning environmental_impact].each do |permit_type|
        test_permit = create(:immo_promo_permit, project: project, permit_type: permit_type)
        controller.params = { permit_id: test_permit.id }
        
        allow(controller).to receive(:compile_submission_package).and_return({})
        allow(controller).to receive(:generate_submission_zip).and_return('/tmp/test.zip')
        
        controller.generate_submission_package
        
        expected_filename = "dossier_#{permit_type}_#{project.reference_number}.zip"
        expect(controller.sent_file[:options][:filename]).to eq(expected_filename)
      end
    end
  end

  describe 'error handling' do
    context 'when permit is not found' do
      before do
        controller.params = { permit_id: 99999 }
      end

      it 'handles missing permit gracefully' do
        expect {
          controller.generate_submission_package
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end