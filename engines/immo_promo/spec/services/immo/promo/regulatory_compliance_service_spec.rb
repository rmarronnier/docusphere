require 'rails_helper'

module Immo
  module Promo
    RSpec.describe RegulatoryComplianceService do
      let(:organization) { create(:organization) }
      let(:project) { create(:immo_promo_project, organization: organization, total_area: 5000) }
      let(:service) { described_class.new(project) }

      describe '#check_all_compliance' do
        it 'checks all compliance categories' do
          result = service.check_all_compliance

          expect(result).to have_key(:rt2020)
          expect(result).to have_key(:accessibility)
          expect(result).to have_key(:fire_safety)
          expect(result).to have_key(:environmental)
          expect(result).to have_key(:urban_planning)
        end

        it 'returns status and issues for each category' do
          result = service.check_all_compliance

          result.each do |category, data|
            expect(data).to have_key(:status)
            expect(data).to have_key(:issues)
            expect(data[:status]).to be_in(%w[compliant non_compliant pending])
            expect(data[:issues]).to be_an(Array)
          end
        end
      end

      describe '#check_regulatory_compliance' do
        it 'returns all identified compliance issues' do
          result = service.check_regulatory_compliance

          expect(result).to have_key(:issues)
          expect(result).to have_key(:compliant)
          expect(result).to have_key(:categories)
          expect(result[:issues]).to be_an(Array)
        end

        it 'marks project as non-compliant when issues exist' do
          allow(service).to receive(:check_all_compliance).and_return(
            rt2020: { status: 'non_compliant', issues: ['Missing energy study'] }
          )

          result = service.check_regulatory_compliance

          expect(result[:compliant]).to be false
          expect(result[:issues]).to include('Missing energy study')
        end

        it 'marks project as compliant when no issues' do
          allow(service).to receive(:check_all_compliance).and_return(
            rt2020: { status: 'compliant', issues: [] }
          )

          result = service.check_regulatory_compliance

          expect(result[:compliant]).to be true
          expect(result[:issues]).to be_empty
        end
      end

      describe '#check_permit_conditions_compliance' do
        let!(:approved_permit) do
          create(:immo_promo_permit,
            project: project,
            status: 'approved',
            permit_type: 'building'
          )
        end

        let!(:pending_condition) do
          create(:immo_promo_permit_condition,
            permit: approved_permit,
            status: 'pending',
            deadline: 5.days.from_now,
            description: 'Submit acoustic study'
          )
        end

        let!(:completed_condition) do
          create(:immo_promo_permit_condition,
            permit: approved_permit,
            status: 'completed',
            description: 'Submit soil analysis'
          )
        end

        it 'identifies pending conditions' do
          result = service.check_permit_conditions_compliance

          expect(result[:pending]).to be_present
          expect(result[:pending].first).to include(
            condition: pending_condition.description,
            deadline: pending_condition.deadline,
            permit_type: 'building'
          )
        end

        it 'tracks completed conditions' do
          result = service.check_permit_conditions_compliance

          expect(result[:completed]).to be_present
          expect(result[:completed].first).to include(
            condition: completed_condition.description
          )
        end

        it 'calculates compliance percentage' do
          result = service.check_permit_conditions_compliance

          expect(result[:compliance_rate]).to eq(50.0)
          expect(result[:total_conditions]).to eq(2)
          expect(result[:completed_count]).to eq(1)
        end

        context 'with overdue conditions' do
          let!(:overdue_condition) do
            create(:immo_promo_permit_condition,
              permit: approved_permit,
              status: 'pending',
              deadline: 2.days.ago
            )
          end

          it 'identifies overdue conditions' do
            result = service.check_permit_conditions_compliance

            expect(result[:overdue]).to be_present
            expect(result[:overdue].size).to eq(1)
          end
        end
      end

      describe '#compliance_summary' do
        let!(:permits) do
          [
            create(:immo_promo_permit, project: project, status: 'approved'),
            create(:immo_promo_permit, project: project, status: 'submitted')
          ]
        end

        it 'generates comprehensive compliance summary' do
          summary = service.compliance_summary

          expect(summary).to have_key(:overall_score)
          expect(summary).to have_key(:by_category)
          expect(summary).to have_key(:critical_issues)
          expect(summary).to have_key(:recommendations)
          expect(summary).to have_key(:next_deadlines)
        end

        it 'calculates overall compliance score' do
          summary = service.compliance_summary

          expect(summary[:overall_score]).to be_between(0, 100)
        end

        it 'provides actionable recommendations' do
          allow(service).to receive(:check_all_compliance).and_return(
            rt2020: { status: 'non_compliant', issues: ['Missing thermal study'] }
          )

          summary = service.compliance_summary

          expect(summary[:recommendations]).to be_present
          expect(summary[:recommendations]).to be_an(Array)
        end
      end

      describe 'specific compliance checks' do
        describe '#check_rt2020_compliance' do
          it 'checks thermal regulations compliance' do
            result = service.send(:check_rt2020_compliance)

            expect(result[:status]).to be_present
            expect(result[:issues]).to be_an(Array)
          end

          context 'with large projects' do
            before do
              project.update(total_area: 10000)
            end

            it 'requires additional studies for large buildings' do
              result = service.send(:check_rt2020_compliance)

              expect(result[:issues]).to include(match(/étude thermique dynamique/))
            end
          end
        end

        describe '#check_accessibility_compliance' do
          it 'checks accessibility requirements' do
            result = service.send(:check_accessibility_compliance)

            expect(result[:status]).to be_present
            expect(result[:issues]).to be_an(Array)
          end

          context 'with public building' do
            before do
              project.update(building_type: 'public')
            end

            it 'applies stricter accessibility rules' do
              result = service.send(:check_accessibility_compliance)

              expect(result[:issues]).to include(match(/ERP/))
            end
          end
        end

        describe '#check_environmental_compliance' do
          it 'checks environmental regulations' do
            result = service.send(:check_environmental_compliance)

            expect(result[:status]).to be_present
            expect(result[:issues]).to be_an(Array)
          end

          context 'near protected area' do
            before do
              project.update(metadatum: { near_protected_area: true })
            end

            it 'requires environmental impact study' do
              result = service.send(:check_environmental_compliance)

              expect(result[:issues]).to include(match(/étude d'impact/))
            end
          end
        end
      end
    end
  end
end