require 'rails_helper'

RSpec.describe Immo::Promo::Milestone, type: :model do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:phase) { create(:immo_promo_phase, project: project) }
  let(:milestone) { create(:immo_promo_milestone, project: project, phase: phase) }

  describe 'associations' do
    it { is_expected.to belong_to(:project).class_name('Immo::Promo::Project') }
    it { is_expected.to belong_to(:phase).class_name('Immo::Promo::Phase').optional }
  end

  describe 'concerns' do
    it 'includes Schedulable' do
      expect(milestone).to respond_to(:start_date)
      expect(milestone).to respond_to(:end_date)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:milestone_type) }
  end

  describe 'enums' do
    it 'defines milestone_type enum' do
      expect(milestone).to respond_to(:milestone_type)
      expect(milestone).to respond_to(:status)
    end
  end

  describe 'scopes' do
    let!(:critical_milestone) { create(:immo_promo_milestone, project: project, is_critical: true) }
    let!(:normal_milestone) { create(:immo_promo_milestone, project: project, is_critical: false) }

    describe '.critical' do
      it 'returns critical milestones' do
        milestones = Immo::Promo::Milestone.critical
        expect(milestones).to include(critical_milestone)
        expect(milestones).not_to include(normal_milestone)
      end
    end
  end

  describe '#is_overdue?' do
    it 'checks if milestone is overdue' do
      milestone.update!(due_date: 1.day.ago, status: 'pending')
      expect(milestone.is_overdue?).to be true
      
      milestone.update!(due_date: 1.day.from_now)
      expect(milestone.is_overdue?).to be false
    end
  end

  describe '#days_until_due' do
    it 'calculates days until due date' do
      milestone.update!(due_date: 5.days.from_now)
      expect(milestone.days_until_due).to eq(5)
    end
  end
end