require 'rails_helper'

RSpec.describe Immo::Promo::Project, type: :model do
  describe 'associations' do
    it { should belong_to(:organization) }
    it { should belong_to(:project_manager).class_name('User').optional }
    it { should have_many(:phases).dependent(:destroy) }
    it { should have_many(:tasks).dependent(:destroy) }
    it { should have_many(:stakeholders).dependent(:destroy) }
    it { should have_many(:permits).dependent(:destroy) }
    it { should have_many(:lots).dependent(:destroy) }
    it { should have_many(:reservations).through(:lots) }
    it { should have_many(:risks).dependent(:destroy) }
    it { should have_many(:milestones).dependent(:destroy) }
    it { should have_many(:budget_lines).dependent(:destroy) }
    it { should have_many(:contracts).dependent(:destroy) }
    it { should have_many(:progress_reports).dependent(:destroy) }
  end
  
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:reference_number) }
    it { should validate_presence_of(:project_type) }
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:start_date) }
    
    it 'validates uniqueness of reference_number' do
      create(:immo_promo_project, reference_number: 'PROJ-001')
      duplicate = build(:immo_promo_project, reference_number: 'PROJ-001')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:reference_number]).to include('has already been taken')
    end
    
    it 'validates end_date is after start_date' do
      project = build(:immo_promo_project,
        start_date: Date.current,
        expected_completion_date: Date.current - 1.day
      )
      expect(project).not_to be_valid
    end
  end
  
  describe 'enums' do
    it { should define_enum_for(:project_type).with_values(
      residential: 'residential',
      commercial: 'commercial',
      mixed: 'mixed',
      office: 'office',
      industrial: 'industrial'
    ) }
    
    it { should define_enum_for(:status).with_values(
      planning: 'planning',
      approved: 'approved',
      construction: 'construction',
      completed: 'completed',
      on_hold: 'on_hold',
      cancelled: 'cancelled'
    ) }
  end
  
  describe 'monetize' do
    it 'monetizes total_budget' do
      project = create(:immo_promo_project, total_budget_cents: 1_000_000_00)
      expect(project.total_budget).to be_a(Money)
      expect(project.total_budget.cents).to eq(1_000_000_00)
      expect(project.total_budget.currency.iso_code).to eq('EUR')
    end
    
    it 'monetizes actual_budget' do
      project = create(:immo_promo_project, actual_budget_cents: 950_000_00)
      expect(project.actual_budget).to be_a(Money)
      expect(project.actual_budget.cents).to eq(950_000_00)
    end
  end
  
  describe 'methods' do
    let(:project) { create(:immo_promo_project) }
    
    describe '#completion_percentage' do
      it 'returns 0 when no tasks exist' do
        expect(project.completion_percentage).to eq(0)
      end
      
      it 'calculates percentage based on completed tasks' do
        create_list(:immo_promo_task, 3, project: project, status: 'completed')
        create_list(:immo_promo_task, 2, project: project, status: 'pending')
        expect(project.completion_percentage).to eq(60)
      end
    end
    
    describe '#days_remaining' do
      it 'returns days until expected completion' do
        project = create(:immo_promo_project, 
          expected_completion_date: Date.current + 30.days
        )
        expect(project.days_remaining).to eq(30)
      end
      
      it 'returns negative days if past due' do
        project = create(:immo_promo_project,
          expected_completion_date: Date.current - 10.days
        )
        expect(project.days_remaining).to eq(-10)
      end
    end
    
    describe '#is_on_schedule?' do
      it 'returns true when on schedule' do
        project = create(:immo_promo_project)
        allow(project).to receive(:completion_percentage).and_return(50)
        allow(project).to receive(:expected_progress_percentage).and_return(45)
        expect(project.is_on_schedule?).to be true
      end
      
      it 'returns false when behind schedule' do
        project = create(:immo_promo_project)
        allow(project).to receive(:completion_percentage).and_return(30)
        allow(project).to receive(:expected_progress_percentage).and_return(50)
        expect(project.is_on_schedule?).to be false
      end
    end
    
    describe '#budget_variance' do
      it 'calculates budget variance' do
        project = create(:immo_promo_project,
          total_budget_cents: 1_000_000_00,
          actual_budget_cents: 950_000_00
        )
        expect(project.budget_variance.cents).to eq(50_000_00)
      end
    end
    
    describe '#can_start_construction?' do
      it 'returns false when no building permit' do
        project = create(:immo_promo_project)
        expect(project.can_start_construction?).to be false
      end
      
      it 'returns true when building permit is approved' do
        project = create(:immo_promo_project)
        create(:immo_promo_permit, :building, :approved, project: project)
        expect(project.can_start_construction?).to be true
      end
    end
    
    describe '#total_surface_area' do
      it 'sums surface area of all lots' do
        project = create(:immo_promo_project)
        create(:immo_promo_lot, project: project, surface_area: 100)
        create(:immo_promo_lot, project: project, surface_area: 150)
        expect(project.total_surface_area).to eq(250)
      end
    end
    
    describe '#sold_percentage' do
      it 'calculates percentage of sold lots' do
        project = create(:immo_promo_project)
        create_list(:immo_promo_lot, 3, :sold, project: project)
        create_list(:immo_promo_lot, 2, project: project)
        expect(project.sold_percentage).to eq(60)
      end
    end
  end
  
  describe 'concerns' do
    it 'includes Schedulable' do
      expect(described_class.ancestors).to include(Schedulable)
    end
    
    it 'responds to Schedulable methods' do
      project = create(:immo_promo_project)
      expect(project).to respond_to(:is_scheduled?)
      expect(project).to respond_to(:duration_days)
    end
  end
end