require 'rails_helper'

RSpec.describe Immo::Promo::DocumentWorkflowService do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization, project_manager: user) }
  let(:phase) { create(:immo_promo_phase, project: project, name: 'Construction', phase_type: 'construction') }
  let(:service) { described_class.new(project, user) }

  describe '#upload_document_with_context' do
    let(:file) { fixture_file_upload('spec/fixtures/sample_document.pdf', 'application/pdf') }

    it 'uploads document with project context' do
      document = service.upload_document_with_context(
        file,
        category: 'technical',
        title: 'Plan de construction'
      )

      expect(document).to be_persisted
      expect(document.title).to eq('Plan de construction')
      expect(document.document_category).to eq('technical')
      expect(document.documentable).to eq(project)
      expect(document.uploaded_by).to eq(user)
    end

    it 'links document to phase when phase_id provided' do
      document = service.upload_document_with_context(
        file,
        category: 'technical',
        phase_id: phase.id
      )

      phase_metadata = document.metadata.find_by(key: 'phase_id')
      expect(phase_metadata.value).to eq(phase.id.to_s)
      
      phase_name_metadata = document.metadata.find_by(key: 'phase_name')
      expect(phase_name_metadata.value).to eq(phase.name)
    end

    it 'adds project-specific metadata' do
      document = service.upload_document_with_context(
        file,
        category: 'technical'
      )

      project_metadata = document.metadata.find_by(key: 'project_id')
      expect(project_metadata.value).to eq(project.id.to_s)
      
      project_type_metadata = document.metadata.find_by(key: 'project_type')
      expect(project_type_metadata.value).to eq(project.project_type)
    end

    context 'with critical document category' do
      it 'automatically requests validation for permit documents' do
        expect(service).to receive(:request_project_validation).with([kind_of(Integer)], priority: 'high')
        
        service.upload_document_with_context(
          file,
          category: 'permit'
        )
      end

      it 'automatically requests validation for legal documents' do
        expect(service).to receive(:request_project_validation).with([kind_of(Integer)], priority: 'high')
        
        service.upload_document_with_context(
          file,
          category: 'legal'
        )
      end
    end
  end

  describe '#batch_upload_for_phase' do
    let(:files) do
      [
        fixture_file_upload('spec/fixtures/sample_document.pdf', 'application/pdf'),
        fixture_file_upload('spec/fixtures/sample_plan.dwg', 'application/dwg')
      ]
    end

    it 'uploads multiple documents for a phase' do
      documents = service.batch_upload_for_phase(files, phase.id, category: 'plan')

      expect(documents).to have(2).items
      documents.each do |doc|
        expect(doc.documentable).to eq(project)
        expect(doc.document_category).to eq('plan')
        expect(doc.metadata.find_by(key: 'phase_id').value).to eq(phase.id.to_s)
      end
    end

    it 'generates contextual titles for uploaded documents' do
      documents = service.batch_upload_for_phase(files, phase.id, category: 'technical')

      expected_title_pattern = /#{Regexp.escape(project.name)} - #{Regexp.escape(phase.name)} - Technical/
      documents.each do |doc|
        expect(doc.title).to match(expected_title_pattern)
      end
    end

    it 'checks phase document completeness after upload' do
      expect(service).to receive(:check_phase_document_completeness).with(phase)
      
      service.batch_upload_for_phase(files, phase.id)
    end
  end

  describe '#share_with_project_stakeholders' do
    let!(:stakeholder1) { create(:immo_promo_stakeholder, project: project, user: user, role: 'architect') }
    let!(:stakeholder2) { create(:immo_promo_stakeholder, project: project, role: 'contractor') }
    let!(:document) { create(:document, documentable: project, uploaded_by: user) }

    it 'shares documents with all stakeholders when role is "all"' do
      shares = service.share_with_project_stakeholders(
        [document.id],
        stakeholder_roles: ['all']
      )

      expect(shares).to have(2).items
    end

    it 'shares documents with specific stakeholder roles' do
      shares = service.share_with_project_stakeholders(
        [document.id],
        stakeholder_roles: ['architect']
      )

      expect(shares).to have(1).item
    end

    it 'sets correct permission level' do
      shares = service.share_with_project_stakeholders(
        [document.id],
        stakeholder_roles: ['architect'],
        permission_level: 'write'
      )

      expect(shares.first.access_level).to eq('write')
    end

    it 'notifies stakeholders about shared documents' do
      expect(service).to receive(:notify_stakeholders_about_documents)
        .with(kind_of(ActiveRecord::Relation), [document.id])
      
      service.share_with_project_stakeholders([document.id])
    end
  end

  describe '#request_project_validation' do
    let!(:direction_user) { create(:user, organization: organization) }
    let!(:direction_profile) { create(:user_profile, user: direction_user, profile_type: 'direction', active: true) }
    let!(:document) { create(:document, documentable: project, uploaded_by: user) }

    before do
      direction_user.update!(active_profile: direction_profile)
    end

    it 'creates validation requests for specified documents' do
      validations = service.request_project_validation(
        [document.id],
        validator_roles: ['direction']
      )

      expect(validations).to have(1).item
      expect(validations.first.assigned_to).to eq(direction_user)
      expect(validations.first.requester).to eq(user)
    end

    it 'sets appropriate due date based on priority' do
      validation = service.request_project_validation(
        [document.id],
        priority: 'high'
      ).first

      expect(validation.due_date).to be_within(1.hour).of(2.business_days.from_now)
    end

    it 'generates validation context with project information' do
      validation = service.request_project_validation([document.id]).first

      expect(validation.notes).to include(project.name)
      expect(validation.notes).to include(project.project_type.humanize)
      expect(validation.notes).to include(project.status.humanize)
    end
  end

  describe '#generate_phase_compliance_report' do
    let!(:permit_doc) { create(:document, documentable: phase, document_category: 'permit', uploaded_by: user) }
    let!(:technical_doc) { create(:document, documentable: phase, document_category: 'technical', uploaded_by: user) }

    it 'generates comprehensive compliance report for phase' do
      report = service.generate_phase_compliance_report(phase.id)

      expect(report[:phase_name]).to eq(phase.name)
      expect(report[:phase_type]).to eq(phase.phase_type)
      expect(report[:required_documents]).to include('permit', 'technical', 'plan', 'administrative')
    end

    it 'identifies present and missing document types' do
      report = service.generate_phase_compliance_report(phase.id)

      expect(report[:compliance_status]['permit'][:present]).to be true
      expect(report[:compliance_status]['permit'][:count]).to eq(1)
      expect(report[:compliance_status]['technical'][:present]).to be true
      expect(report[:missing_documents]).to include('plan', 'administrative')
    end

    it 'tracks pending validations' do
      validation_request = create(:validation_request, 
        validatable: permit_doc,
        requester: user,
        status: 'pending'
      )

      report = service.generate_phase_compliance_report(phase.id)

      pending_validation = report[:pending_validations].find { |pv| pv[:document_type] == 'permit' }
      expect(pending_validation[:count]).to eq(1)
    end

    it 'generates actionable recommendations' do
      report = service.generate_phase_compliance_report(phase.id)

      # Should recommend uploading missing documents
      missing_doc_recommendations = report[:recommendations].select { |r| r[:type] == 'missing_document' }
      expect(missing_doc_recommendations).not_to be_empty
    end
  end

  describe '#auto_categorize_document' do
    it 'categorizes plan documents correctly' do
      file = double('file', original_filename: 'architectural_plan.dwg')
      
      result = service.auto_categorize_document(file)
      
      expect(result[:category]).to eq('plan')
      expect(result[:suggested_tags]).to include('plans', 'architecture', 'conception')
    end

    it 'categorizes permit documents correctly' do
      file = double('file', original_filename: 'permis_de_construire.pdf')
      
      result = service.auto_categorize_document(file)
      
      expect(result[:category]).to eq('permit')
      expect(result[:suggested_tags]).to include('permis', 'réglementation', 'autorisation')
    end

    it 'categorizes financial documents correctly' do
      file = double('file', original_filename: 'budget_construction.xlsx')
      
      result = service.auto_categorize_document(file)
      
      expect(result[:category]).to eq('financial')
      expect(result[:suggested_tags]).to include('budget', 'coûts', 'financement')
    end

    it 'defaults to project category for unknown files' do
      file = double('file', original_filename: 'unknown_document.txt')
      
      result = service.auto_categorize_document(file)
      
      expect(result[:category]).to eq('project')
      expect(result[:suggested_tags]).to include('général')
    end

    it 'generates appropriate suggested title' do
      file = double('file', original_filename: 'technical_specification.pdf')
      
      result = service.auto_categorize_document(file)
      
      expect(result[:suggested_title]).to include(project.name)
      expect(result[:suggested_title]).to include('Technical')
    end
  end

  describe 'private methods' do
    describe '#required_documents_for_phase' do
      it 'returns correct document types for permits phase' do
        permits_phase = create(:immo_promo_phase, project: project, phase_type: 'permits')
        
        required_docs = service.send(:required_documents_for_phase, permits_phase)
        
        expect(required_docs).to include('permit', 'administrative', 'legal', 'plan')
      end

      it 'returns correct document types for construction phase' do
        construction_phase = create(:immo_promo_phase, project: project, phase_type: 'construction')
        
        required_docs = service.send(:required_documents_for_phase, construction_phase)
        
        expect(required_docs).to include('permit', 'technical', 'plan', 'administrative')
      end
    end

    describe '#generate_suggested_tags' do
      it 'includes project-specific tags' do
        tags = service.send(:generate_suggested_tags, 'technical')
        
        expect(tags).to include(project.project_type)
        expect(tags).to include(project.status)
        expect(tags).to include('technique', 'spécifications', 'études')
      end
    end
  end
end