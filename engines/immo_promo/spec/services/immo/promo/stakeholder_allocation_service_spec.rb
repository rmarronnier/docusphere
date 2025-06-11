require 'rails_helper'

module Immo
  module Promo
    RSpec.describe StakeholderAllocationService do
      let(:organization) { create(:organization) }
      let(:project) { create(:immo_promo_project, organization: organization) }
      let(:phase) { create(:immo_promo_phase, project: project) }
      let(:service) { described_class.new(project) }

      let!(:architect) do
        create(:immo_promo_stakeholder,
          project: project,
          role: 'architect',
          skills: ['design', 'planning', 'permits'],
          availability: 80
        )
      end

      let!(:engineer) do
        create(:immo_promo_stakeholder,
          project: project,
          role: 'engineer',
          skills: ['structural', 'calculations', 'technical'],
          availability: 60
        )
      end

      let!(:contractor) do
        create(:immo_promo_stakeholder,
          project: project,
          role: 'contractor',
          skills: ['construction', 'management', 'coordination'],
          availability: 90
        )
      end

      describe '#optimize_team_allocation' do
        let!(:design_task) do
          create(:immo_promo_task,
            phase: phase,
            required_skills: ['design', 'planning'],
            estimated_hours: 40
          )
        end

        let!(:technical_task) do
          create(:immo_promo_task,
            phase: phase,
            required_skills: ['structural', 'technical'],
            estimated_hours: 30
          )
        end

        it 'allocates stakeholders based on skills match' do
          result = service.optimize_team_allocation

          expect(result[:allocations]).to be_present
          expect(result[:allocations][design_task.id]).to eq(architect.id)
          expect(result[:allocations][technical_task.id]).to eq(engineer.id)
        end

        it 'considers stakeholder availability' do
          architect.update(availability: 10)

          result = service.optimize_team_allocation

          expect(result[:warnings]).to include(match(/surcharge/))
        end

        it 'provides allocation efficiency score' do
          result = service.optimize_team_allocation

          expect(result[:efficiency_score]).to be_between(0, 100)
          expect(result[:skill_coverage]).to be_between(0, 100)
        end

        it 'identifies unallocated tasks' do
          create(:immo_promo_task,
            phase: phase,
            required_skills: ['non_existent_skill']
          )

          result = service.optimize_team_allocation

          expect(result[:unallocated_tasks]).to be_present
        end
      end

      describe '#suggest_stakeholder_for_task' do
        let(:task) do
          create(:immo_promo_task,
            phase: phase,
            required_skills: ['design', 'permits']
          )
        end

        it 'suggests best matched stakeholder' do
          suggestion = service.suggest_stakeholder_for_task(task)

          expect(suggestion[:stakeholder]).to eq(architect)
          expect(suggestion[:match_score]).to be > 0
        end

        it 'provides match reasoning' do
          suggestion = service.suggest_stakeholder_for_task(task)

          expect(suggestion[:reasons]).to include(match(/compétences/))
          expect(suggestion[:reasons]).to include(match(/disponibilité/))
        end

        context 'with no suitable stakeholder' do
          let(:impossible_task) do
            create(:immo_promo_task,
              phase: phase,
              required_skills: ['underwater_basketweaving']
            )
          end

          it 'returns nil stakeholder with explanation' do
            suggestion = service.suggest_stakeholder_for_task(impossible_task)

            expect(suggestion[:stakeholder]).to be_nil
            expect(suggestion[:reasons]).to include(match(/Aucun intervenant/))
          end
        end
      end

      describe '#coordinate_interventions' do
        let(:start_date) { Date.today }
        let(:end_date) { start_date + 30.days }

        let!(:task1) do
          create(:immo_promo_task,
            phase: phase,
            assigned_to: architect,
            planned_start_date: start_date,
            planned_end_date: start_date + 5.days
          )
        end

        let!(:task2) do
          create(:immo_promo_task,
            phase: phase,
            assigned_to: architect,
            planned_start_date: start_date + 3.days,
            planned_end_date: start_date + 8.days
          )
        end

        it 'identifies scheduling conflicts' do
          result = service.coordinate_interventions(start_date, end_date)

          expect(result[:conflicts]).to be_present
          expect(result[:conflicts].first).to include(
            stakeholder: architect,
            conflicting_tasks: [task1, task2]
          )
        end

        it 'suggests alternative scheduling' do
          result = service.coordinate_interventions(start_date, end_date)

          expect(result[:suggestions]).to be_present
          expect(result[:suggestions].first).to include(:new_start_date, :new_end_date)
        end

        it 'calculates resource utilization' do
          result = service.coordinate_interventions(start_date, end_date)

          expect(result[:utilization]).to be_present
          expect(result[:utilization][architect.id]).to have_key(:percentage)
          expect(result[:utilization][architect.id]).to have_key(:hours)
        end
      end

      describe '#detect_conflicts' do
        context 'with resource conflicts' do
          let!(:concurrent_tasks) do
            2.times.map do
              create(:immo_promo_task,
                phase: phase,
                assigned_to: architect,
                planned_start_date: Date.today,
                planned_end_date: Date.today + 3.days
              )
            end
          end

          it 'detects resource overallocation' do
            conflicts = service.detect_conflicts

            expect(conflicts[:resource_conflicts]).to be_present
            expect(conflicts[:resource_conflicts].first[:stakeholder]).to eq(architect)
          end
        end

        context 'with skill gaps' do
          let!(:unmatched_task) do
            create(:immo_promo_task,
              phase: phase,
              required_skills: ['plumbing', 'electrical']
            )
          end

          it 'detects missing skills' do
            conflicts = service.detect_conflicts

            expect(conflicts[:skill_gaps]).to be_present
            expect(conflicts[:skill_gaps].first[:missing_skills]).to include('plumbing', 'electrical')
          end
        end

        context 'with availability issues' do
          before do
            architect.update(availability: 20)
          end

          let!(:heavy_task) do
            create(:immo_promo_task,
              phase: phase,
              assigned_to: architect,
              estimated_hours: 100
            )
          end

          it 'detects availability conflicts' do
            conflicts = service.detect_conflicts

            expect(conflicts[:availability_issues]).to be_present
            expect(conflicts[:availability_issues].first[:stakeholder]).to eq(architect)
          end
        end
      end

      describe '#task_distribution' do
        let!(:tasks) do
          [
            create(:immo_promo_task, phase: phase, assigned_to: architect),
            create(:immo_promo_task, phase: phase, assigned_to: architect),
            create(:immo_promo_task, phase: phase, assigned_to: engineer),
            create(:immo_promo_task, phase: phase, assigned_to: nil)
          ]
        end

        it 'analyzes current task distribution' do
          analysis = service.task_distribution

          expect(analysis[:by_stakeholder]).to be_present
          expect(analysis[:by_stakeholder][architect.id][:count]).to eq(2)
          expect(analysis[:by_stakeholder][engineer.id][:count]).to eq(1)
        end

        it 'identifies unassigned tasks' do
          analysis = service.task_distribution

          expect(analysis[:unassigned_count]).to eq(1)
          expect(analysis[:unassigned_tasks]).to be_present
        end

        it 'calculates distribution metrics' do
          analysis = service.task_distribution

          expect(analysis[:metrics]).to include(
            :average_tasks_per_stakeholder,
            :distribution_variance,
            :balance_score
          )
        end
      end

      describe '#recommendations' do
        before do
          # Create imbalanced allocation
          5.times do
            create(:immo_promo_task, phase: phase, assigned_to: architect)
          end
        end

        it 'provides reallocation recommendations' do
          recommendations = service.recommendations

          expect(recommendations[:reallocations]).to be_present
          expect(recommendations[:reallocations].first).to include(
            :from_stakeholder,
            :to_stakeholder,
            :task,
            :reason
          )
        end

        it 'suggests hiring needs' do
          create(:immo_promo_task,
            phase: phase,
            required_skills: ['rare_skill']
          )

          recommendations = service.recommendations

          expect(recommendations[:hiring_needs]).to be_present
          expect(recommendations[:hiring_needs].first).to include(:skills_needed)
        end

        it 'identifies training opportunities' do
          recommendations = service.recommendations

          expect(recommendations[:training_suggestions]).to be_present
        end
      end
    end
  end
end