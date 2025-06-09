require 'rails_helper'

RSpec.describe Immo::Promo::TimeLog, type: :model do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:task) { create(:immo_promo_task, project: project) }
  let(:user) { create(:user, organization: organization) }
  let(:time_log) { create(:immo_promo_time_log, task: task, user: user) }

  describe 'associations' do
    it { is_expected.to belong_to(:task).class_name('Immo::Promo::Task') }
    it { is_expected.to belong_to(:user).class_name('User') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:hours_spent) }
    it { is_expected.to validate_presence_of(:work_date) }
    it { is_expected.to validate_numericality_of(:hours_spent).is_greater_than(0) }
  end

  describe 'scopes' do
    let!(:todays_log) { create(:immo_promo_time_log, task: task, user: user, work_date: Date.current) }
    let!(:yesterdays_log) { create(:immo_promo_time_log, task: task, user: user, work_date: 1.day.ago) }

    describe '.for_date' do
      it 'returns time logs for specific date' do
        logs = Immo::Promo::TimeLog.for_date(Date.current)
        expect(logs).to include(todays_log)
        expect(logs).not_to include(yesterdays_log)
      end
    end
  end

  describe '#billable_amount' do
    it 'calculates billable amount when hourly_rate is set' do
      time_log.update!(hours_spent: 8.0, hourly_rate_cents: 5000_00)
      expect(time_log.billable_amount).to eq(Money.new(40000_00, 'EUR'))
    end

    it 'returns zero when no hourly_rate' do
      time_log.update!(hours_spent: 8.0, hourly_rate_cents: nil)
      expect(time_log.billable_amount).to eq(Money.new(0, 'EUR'))
    end
  end
end