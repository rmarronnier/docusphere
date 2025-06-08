require 'rails_helper'

RSpec.describe Immo::Promo::Project, type: :model do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization, project_manager: user) }

  describe 'associations' do
    it { should belong_to(:organization) }
    it { should belong_to(:project_manager).class_name('User').optional }
    it { should have_many(:phases).class_name('Immo::Promo::Phase').dependent(:destroy) }
    it { should have_many(:lots).class_name('Immo::Promo::Lot').dependent(:destroy) }
    it { should have_many(:stakeholders).class_name('Immo::Promo::Stakeholder').dependent(:destroy) }
    it { should have_many(:permits).class_name('Immo::Promo::Permit').dependent(:destroy) }
    it { should have_many(:budgets).class_name('Immo::Promo::Budget').dependent(:destroy) }
    it { should have_many(:contracts).class_name('Immo::Promo::Contract').dependent(:destroy) }
    it { should have_many(:risks).class_name('Immo::Promo::Risk').dependent(:destroy) }
    it { should have_many(:milestones).through(:phases).class_name('Immo::Promo::Milestone') }
    it { should have_many(:progress_reports).class_name('Immo::Promo::ProgressReport').dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:project_type) }
    it { should validate_presence_of(:status) }
  end

  describe 'enums' do
    it { should define_enum_for(:project_type).backed_by_column_of_type(:string).with_values(
      residential: 'residential',
      commercial: 'commercial',
      mixed: 'mixed',
      office: 'office',
      retail: 'retail',
      industrial: 'industrial'
    ) }

    it { should define_enum_for(:status).backed_by_column_of_type(:string).with_values(
      planning: 'planning',
      pre_construction: 'pre_construction',
      construction: 'construction',
      finishing: 'finishing',
      delivered: 'delivered',
      completed: 'completed',
      cancelled: 'cancelled'
    ) }
  end

  describe 'monetization' do
    it { should monetize(:total_budget) }
    it { should monetize(:current_budget) }
  end

  describe 'scopes' do
    describe '.active' do
      it 'returns projects not completed or cancelled' do
        active_project = create(:immo_promo_project, status: 'construction')
        completed_project = create(:immo_promo_project, status: 'completed')
        cancelled_project = create(:immo_promo_project, status: 'cancelled')

        expect(Immo::Promo::Project.active).to include(active_project)
        expect(Immo::Promo::Project.active).not_to include(completed_project, cancelled_project)
      end
    end

    describe '.by_type' do
      it 'filters projects by type' do
        residential = create(:immo_promo_project, project_type: 'residential')
        commercial = create(:immo_promo_project, project_type: 'commercial')

        expect(Immo::Promo::Project.by_type('residential')).to include(residential)
        expect(Immo::Promo::Project.by_type('residential')).not_to include(commercial)
      end
    end

    describe '.by_manager' do
      it 'filters projects by manager' do
        manager1 = create(:user)
        manager2 = create(:user)
        project1 = create(:immo_promo_project, project_manager: manager1)
        project2 = create(:immo_promo_project, project_manager: manager2)

        expect(Immo::Promo::Project.by_manager(manager1)).to include(project1)
        expect(Immo::Promo::Project.by_manager(manager1)).not_to include(project2)
      end
    end
  end

  describe '#completion_percentage' do
    context 'with no phases' do
      it 'returns 0' do
        expect(project.completion_percentage).to eq(0)
      end
    end

    context 'with phases' do
      it 'calculates the percentage of completed phases' do
        create(:immo_promo_phase, project: project, status: 'completed')
        create(:immo_promo_phase, project: project, status: 'completed')
        create(:immo_promo_phase, project: project, status: 'in_progress')
        create(:immo_promo_phase, project: project, status: 'pending')

        expect(project.completion_percentage).to eq(50.0)
      end
    end
  end

  describe '#is_delayed?' do
    context 'without end_date' do
      it 'returns false' do
        project.end_date = nil
        expect(project.is_delayed?).to be_falsey
      end
    end

    context 'with phases ending after project end_date' do
      it 'returns true' do
        project.end_date = 1.month.from_now
        create(:immo_promo_phase, project: project, end_date: 2.months.from_now, status: 'in_progress')
        
        expect(project.is_delayed?).to be_truthy
      end
    end

    context 'with all phases on schedule' do
      it 'returns false' do
        project.end_date = 2.months.from_now
        create(:immo_promo_phase, project: project, end_date: 1.month.from_now, status: 'in_progress')
        
        expect(project.is_delayed?).to be_falsey
      end
    end
  end

  describe '#total_surface_area' do
    it 'returns the sum of all lots surface areas' do
      create(:immo_promo_lot, project: project, surface_area: 100)
      create(:immo_promo_lot, project: project, surface_area: 150)
      create(:immo_promo_lot, project: project, surface_area: 75)

      expect(project.total_surface_area).to eq(325)
    end

    it 'returns 0 when no lots exist' do
      expect(project.total_surface_area).to eq(0)
    end
  end

  describe '#can_start_construction?' do
    it 'returns true when construction permit is approved' do
      create(:immo_promo_permit, project: project, permit_type: 'construction', status: 'approved')
      expect(project.can_start_construction?).to be_truthy
    end

    it 'returns false when construction permit is not approved' do
      create(:immo_promo_permit, project: project, permit_type: 'construction', status: 'submitted')
      expect(project.can_start_construction?).to be_falsey
    end

    it 'returns false when no construction permit exists' do
      expect(project.can_start_construction?).to be_falsey
    end
  end

  describe 'callbacks' do
    describe 'before_validation' do
      it 'sets slug from name' do
        project = build(:immo_promo_project, name: 'Mon Projet Test', slug: nil)
        project.valid?
        expect(project.slug).to eq('mon-projet-test')
      end

      it 'generates reference_number' do
        project = build(:immo_promo_project, organization: organization, reference_number: nil)
        project.valid?
        expect(project.reference_number).to match(/^PROJ-#{organization.id}-\d{14}$/)
      end
    end
  end

  describe 'concerns' do
    it_behaves_like 'addressable'
    it_behaves_like 'schedulable'
    it_behaves_like 'authorizable'
  end
end