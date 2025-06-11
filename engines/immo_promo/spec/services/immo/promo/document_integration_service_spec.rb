require 'rails_helper'

module Immo
  module Promo
    RSpec.describe DocumentIntegrationService do
      let(:organization) { create(:organization) }
      let(:user) { create(:user, organization: organization) }
      let(:space) { create(:space, organization: organization) }
      let(:project) { create(:immo_promo_project, organization: organization) }
      let(:phase) { create(:immo_promo_phase, project: project) }
      let(:document) do
        doc = create(:document, space: space, uploaded_by: user)
        # Allow stubbing methods that don't exist on the model
        allow(doc).to receive(:ai_classification).and_return(nil)
        allow(doc).to receive(:extracted_entities).and_return({})
        doc
      end
      let(:service) { described_class.new(document, project) }

      describe '#process_document' do
        context 'when document and documentable are present' do
          it 'processes the document through all steps' do
            expect(service).to receive(:extract_real_estate_metadata)
            expect(service).to receive(:auto_categorize_document)
            expect(service).to receive(:create_document_relationships)
            expect(service).to receive(:check_compliance_requirements)
            expect(service).to receive(:notify_relevant_stakeholders)

            expect(service.process_document).to be true
          end

          it 'returns true on success' do
            allow(service).to receive(:extract_real_estate_metadata)
            allow(service).to receive(:auto_categorize_document)
            allow(service).to receive(:create_document_relationships)
            allow(service).to receive(:check_compliance_requirements)
            allow(service).to receive(:notify_relevant_stakeholders)

            expect(service.process_document).to be true
          end

          it 'returns false and logs error on failure' do
            allow(service).to receive(:extract_real_estate_metadata).and_raise(StandardError, 'Test error')
            
            expect(Rails.logger).to receive(:error).with(/Document integration failed/)
            expect(service.process_document).to be false
          end
        end

        context 'when documentable is nil' do
          let(:service) { described_class.new(document, nil) }

          before do
            allow(document).to receive(:documentable).and_return(nil)
          end

          it 'does not process the document' do
            expect(service).not_to receive(:extract_real_estate_metadata)
            service.process_document
          end
        end
      end

      describe '#extract_real_estate_metadata' do
        it 'extracts permit numbers from content' do
          allow(document).to receive(:extracted_entities).and_return({
            'permit_numbers' => ['PC-2024-001']
          })
          
          expect(service).to receive(:create_or_update_permits).with(['PC-2024-001'])
          service.send(:extract_real_estate_metadata)
        end

        it 'extracts monetary amounts from content' do
          allow(document).to receive(:extracted_entities).and_return({
            'amounts' => ['1 500 000 €']
          })
          
          expect(service).to receive(:update_budget_tracking).with(['1 500 000 €'])
          service.send(:extract_real_estate_metadata)
        end

        it 'extracts dates from content' do
          allow(document).to receive(:extracted_entities).and_return({
            'dates' => ['15/03/2024']
          })
          
          expect(service).to receive(:update_timeline_dates).with(['15/03/2024'])
          service.send(:extract_real_estate_metadata)
        end

        it 'extracts organization names from content' do
          allow(document).to receive(:extracted_entities).and_return({
            'organizations' => ['Construction ABC SARL']
          })
          
          expect(service).to receive(:link_to_stakeholders).with(['Construction ABC SARL'])
          service.send(:extract_real_estate_metadata)
        end
      end

      describe '#auto_categorize_document' do
        context 'with permit document' do
          before do
            allow(document).to receive(:ai_classification).and_return('building_permit')
          end

          it 'sets document category' do
            expect(document).to receive(:update).with(document_category: 'permit')
            service.send(:auto_categorize_document)
          end
        end

        context 'with financial document' do
          before do
            allow(document).to receive(:ai_classification).and_return('invoice')
          end

          it 'sets document category' do
            expect(document).to receive(:update).with(document_category: 'financial')
            service.send(:auto_categorize_document)
          end
        end

        context 'with plan document' do
          before do
            allow(document).to receive(:ai_classification).and_return('architectural_plan')
          end

          it 'sets document category' do
            expect(document).to receive(:update).with(document_category: 'plan')
            service.send(:auto_categorize_document)
          end
        end

        context 'with unknown classification' do
          before do
            allow(document).to receive(:ai_classification).and_return('unknown_type')
          end

          it 'does not update category' do
            expect(document).not_to receive(:update)
            service.send(:auto_categorize_document)
          end
        end
      end

      describe '#create_document_relationships' do
        context 'with permit document' do
          before do
            allow(document).to receive(:document_category).and_return('permit')
          end

          it 'links document to permit phase' do
            expect(service).to receive(:link_to_permit_phase)
            service.send(:create_document_relationships)
          end
        end

        context 'with financial document' do
          before do
            allow(document).to receive(:document_category).and_return('financial')
          end

          it 'links document to budget line' do
            expect(service).to receive(:link_to_budget_line)
            service.send(:create_document_relationships)
          end
        end

        context 'with technical document' do
          before do
            allow(document).to receive(:document_category).and_return('technical')
          end

          it 'links document to current phase' do
            expect(service).to receive(:link_to_current_phase)
            service.send(:create_document_relationships)
          end
        end

        context 'with contract document' do
          before do
            allow(document).to receive(:document_category).and_return('contract')
          end

          it 'links document to stakeholder contract' do
            expect(service).to receive(:link_to_stakeholder_contract)
            service.send(:create_document_relationships)
          end
        end
      end

      describe '#check_compliance_requirements' do
        let(:current_phase) { create(:immo_promo_phase, project: project, status: 'in_progress') }
        let(:project_manager) { create(:user, organization: organization) }

        before do
          allow(project).to receive(:phases).and_return(double(in_progress: double(first: current_phase)))
          allow(project).to receive(:project_manager).and_return(project_manager)
          allow(project).to receive(:documents).and_return(double(pluck: ['permit', 'financial']))
          allow(service).to receive(:required_documents_for_phase).and_return(['permit', 'financial'])
        end

        it 'marks phase compliance as complete when all documents present' do
          expect(current_phase).to receive(:update).with(compliance_status: 'complete')
          
          service.send(:check_compliance_requirements)
        end

        it 'sends notification when compliance is complete' do
          notification_service = instance_double(NotificationService)
          allow(NotificationService).to receive(:new).and_return(notification_service)
          allow(notification_service).to receive(:create_notification)
          
          expect(notification_service).to receive(:create_notification).with(
            hash_including(
              user: project_manager,
              notification_type: 'phase_compliance_complete'
            )
          )
          
          service.send(:check_compliance_requirements)
        end
      end

      describe '#notify_relevant_stakeholders' do
        let(:users_to_notify) { [user, create(:user, organization: organization)] }

        before do
          allow(service).to receive(:determine_notification_recipients).and_return(users_to_notify)
          allow(document).to receive(:title).and_return('Test Document')
          allow(document).to receive(:document_category).and_return('permit')
          allow(project).to receive(:name).and_return('Test Project')
        end

        it 'creates notifications for all relevant users' do
          notification_service = instance_double(NotificationService)
          allow(NotificationService).to receive(:new).and_return(notification_service)
          
          users_to_notify.each do |recipient|
            expect(notification_service).to receive(:create_notification).with(
              hash_including(
                user: recipient,
                notification_type: 'document_uploaded',
                title: 'Nouveau document ajouté',
                metadata: hash_including(
                  document_id: document.id,
                  project_id: project.id,
                  document_category: 'permit'
                )
              )
            )
          end
          
          service.send(:notify_relevant_stakeholders)
        end
      end
    end
  end
end