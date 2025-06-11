require 'rails_helper'

module Immo
  module Promo
    RSpec.describe PermitDeadlineService do
      let(:organization) { create(:organization) }
      let(:project) { create(:immo_promo_project, organization: organization) }
      let(:service) { described_class.new(project) }

      describe '#track_permit_deadlines' do
        let!(:overdue_permit) do
          create(:immo_promo_permit, 
            project: project,
            permit_type: 'building',
            submission_deadline: 2.days.ago,
            status: 'draft'
          )
        end

        let!(:critical_permit) do
          create(:immo_promo_permit,
            project: project,
            permit_type: 'demolition',
            submission_deadline: 3.days.from_now,
            status: 'preparing'
          )
        end

        let!(:upcoming_permit) do
          create(:immo_promo_permit,
            project: project,
            permit_type: 'environmental',
            submission_deadline: 10.days.from_now,
            status: 'draft'
          )
        end

        it 'returns deadlines sorted by urgency' do
          result = service.track_permit_deadlines

          expect(result.first[:type]).to eq('permit_overdue')
          expect(result.first[:item]).to eq(overdue_permit)
          expect(result.second[:type]).to eq('permit_critical')
          expect(result.third[:type]).to eq('permit_upcoming')
        end

        it 'includes all relevant deadline information' do
          result = service.track_permit_deadlines.first

          expect(result).to include(
            type: 'permit_overdue',
            item: overdue_permit,
            deadline: overdue_permit.submission_deadline,
            days_until: be < 0,
            urgency: 'critical'
          )
        end

        context 'with permit conditions' do
          let!(:overdue_condition) do
            create(:immo_promo_permit_condition,
              permit: critical_permit,
              deadline: 1.day.ago,
              status: 'pending'
            )
          end

          it 'includes overdue conditions' do
            result = service.track_permit_deadlines

            condition_alert = result.find { |r| r[:type] == 'condition_overdue' }
            expect(condition_alert).to be_present
            expect(condition_alert[:item]).to eq(overdue_condition)
          end
        end
      end

      describe '#critical_deadlines' do
        let!(:critical_permit) do
          create(:immo_promo_permit,
            project: project,
            submission_deadline: 2.days.from_now,
            status: 'draft'
          )
        end

        let!(:non_critical_permit) do
          create(:immo_promo_permit,
            project: project,
            submission_deadline: 10.days.from_now,
            status: 'draft'
          )
        end

        it 'returns only critical deadlines' do
          result = service.critical_deadlines

          expect(result.size).to eq(1)
          expect(result.first[:item]).to eq(critical_permit)
          expect(result.first[:urgency]).to eq('critical')
        end
      end

      describe '#upcoming_deadlines' do
        let!(:within_range_permit) do
          create(:immo_promo_permit,
            project: project,
            submission_deadline: 5.days.from_now,
            status: 'draft'
          )
        end

        let!(:outside_range_permit) do
          create(:immo_promo_permit,
            project: project,
            submission_deadline: 15.days.from_now,
            status: 'draft'
          )
        end

        it 'returns deadlines within specified days' do
          result = service.upcoming_deadlines(7)

          expect(result.size).to eq(1)
          expect(result.first[:item]).to eq(within_range_permit)
        end

        it 'defaults to 30 days when no parameter given' do
          result = service.upcoming_deadlines

          expect(result.size).to eq(2)
        end
      end

      describe '#overdue_items' do
        let!(:overdue_permit) do
          create(:immo_promo_permit,
            project: project,
            submission_deadline: 2.days.ago,
            status: 'draft'
          )
        end

        let!(:submitted_permit) do
          create(:immo_promo_permit,
            project: project,
            submission_deadline: 2.days.ago,
            status: 'submitted'
          )
        end

        let!(:overdue_condition) do
          create(:immo_promo_permit_condition,
            permit: submitted_permit,
            deadline: 1.day.ago,
            status: 'pending'
          )
        end

        it 'includes overdue permits not yet submitted' do
          result = service.overdue_items

          permit_items = result.select { |r| r[:item].is_a?(Permit) }
          expect(permit_items.size).to eq(1)
          expect(permit_items.first[:item]).to eq(overdue_permit)
        end

        it 'includes overdue conditions' do
          result = service.overdue_items

          condition_items = result.select { |r| r[:item].is_a?(PermitCondition) }
          expect(condition_items.size).to eq(1)
          expect(condition_items.first[:item]).to eq(overdue_condition)
        end

        it 'excludes submitted permits from overdue list' do
          result = service.overdue_items

          expect(result.map { |r| r[:item] }).not_to include(submitted_permit)
        end
      end

      describe '#generate_deadline_calendar' do
        let!(:permit_with_deadline) do
          create(:immo_promo_permit,
            project: project,
            permit_type: 'building',
            submission_deadline: 5.days.from_now,
            approval_deadline: 15.days.from_now
          )
        end

        let!(:condition_with_deadline) do
          create(:immo_promo_permit_condition,
            permit: permit_with_deadline,
            deadline: 10.days.from_now,
            description: 'Submit environmental impact study'
          )
        end

        it 'generates calendar events for all deadlines' do
          calendar = service.generate_deadline_calendar

          expect(calendar[:events].size).to eq(3)
        end

        it 'includes permit submission deadlines' do
          calendar = service.generate_deadline_calendar

          submission_event = calendar[:events].find { |e| e[:title].include?('Submission') }
          expect(submission_event).to be_present
          expect(submission_event[:date]).to eq(permit_with_deadline.submission_deadline.to_date)
          expect(submission_event[:type]).to eq('permit_submission')
        end

        it 'includes permit approval deadlines' do
          calendar = service.generate_deadline_calendar

          approval_event = calendar[:events].find { |e| e[:title].include?('Approval') }
          expect(approval_event).to be_present
          expect(approval_event[:date]).to eq(permit_with_deadline.approval_deadline.to_date)
          expect(approval_event[:type]).to eq('permit_approval')
        end

        it 'includes condition deadlines' do
          calendar = service.generate_deadline_calendar

          condition_event = calendar[:events].find { |e| e[:type] == 'condition' }
          expect(condition_event).to be_present
          expect(condition_event[:date]).to eq(condition_with_deadline.deadline.to_date)
          expect(condition_event[:description]).to include(condition_with_deadline.description)
        end

        it 'sorts events by date' do
          calendar = service.generate_deadline_calendar

          dates = calendar[:events].map { |e| e[:date] }
          expect(dates).to eq(dates.sort)
        end

        it 'includes project information' do
          calendar = service.generate_deadline_calendar

          expect(calendar[:project_id]).to eq(project.id)
          expect(calendar[:project_name]).to eq(project.name)
        end
      end
    end
  end
end