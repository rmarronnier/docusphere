require 'rails_helper'

RSpec.describe Immo::Promo::Project, type: :model do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  
  describe 'associations' do
    it { should belong_to(:organization) }
    it { should belong_to(:project_manager).class_name('User').optional }
    it { should have_many(:phases).dependent(:destroy) }
    it { should have_many(:stakeholders).dependent(:destroy) }
    it { should have_many(:permits).dependent(:destroy) }
    it { should have_many(:budgets).dependent(:destroy) }
    it { should have_many(:lots).dependent(:destroy) }
    it { should have_many(:contracts).dependent(:destroy) }
    it { should have_many(:risks).dependent(:destroy) }
    it { should have_many(:progress_reports).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:immo_promo_project, organization: organization) }
    
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:reference) }
    it { should validate_presence_of(:project_type) }
    it { should validate_uniqueness_of(:reference).scoped_to(:organization_id) }
    # Skip validation tests for enums as they are already validated by Rails enum
  end

  describe 'concerns' do
    it 'includes Addressable' do
      expect(described_class.included_modules).to include(Addressable)
    end
    
    it 'includes Schedulable' do
      expect(described_class.included_modules).to include(Schedulable)
    end
    
    it 'includes WorkflowManageable' do
      expect(described_class.included_modules).to include(WorkflowManageable)
    end
    
    it 'includes Authorizable' do
      expect(described_class.included_modules).to include(Authorizable)
    end
  end

  describe 'monetization' do
    let(:project) { create(:immo_promo_project, organization: organization, total_budget_cents: 100_000_000) }
    
    it 'monetizes total_budget' do
      expect(project.total_budget).to be_a(Money)
      expect(project.total_budget.cents).to eq(100_000_000)
      expect(project.total_budget.currency.to_s).to eq('EUR')
    end
  end

  describe 'enum' do
    it 'defines project_type enum' do
      expect(described_class.project_types).to eq({
        'residential' => 'residential',
        'commercial' => 'commercial',
        'mixed' => 'mixed',
        'industrial' => 'industrial'
      })
    end

    it 'defines status enum' do
      expect(described_class.statuses).to eq({
        'planning' => 'planning',
        'development' => 'development',
        'construction' => 'construction',
        'delivery' => 'delivery',
        'completed' => 'completed',
        'cancelled' => 'cancelled'
      })
    end
  end

  describe 'scopes' do
    let!(:development_project) { create(:immo_promo_project, organization: organization, status: 'development') }
    let!(:completed_project) { create(:immo_promo_project, organization: organization, status: 'completed') }
    let!(:residential_project) { create(:immo_promo_project, organization: organization, project_type: 'residential') }
    let!(:commercial_project) { create(:immo_promo_project, organization: organization, project_type: 'commercial') }

    describe '.active' do
      it 'returns only non-completed projects' do
        expect(described_class.active).to include(development_project)
        expect(described_class.active).not_to include(completed_project)
      end
    end

    describe '.by_type' do
      it 'returns projects of specified type' do
        expect(described_class.by_type('residential')).to include(residential_project)
        expect(described_class.by_type('residential')).not_to include(commercial_project)
      end
    end
  end


  describe 'instance methods' do
    let(:project) { create(:immo_promo_project, organization: organization) }
    
    describe '#completion_percentage' do
      context 'with no phases' do
        it 'returns 0' do
          expect(project.completion_percentage).to eq(0)
        end
      end
      
      context 'with phases' do
        before do
          create(:immo_promo_phase, project: project, status: 'completed')
          create(:immo_promo_phase, project: project, status: 'in_progress')
        end
        
        it 'calculates completion based on completed phases' do
          expect(project.completion_percentage).to eq(50.0)
        end
      end
    end
    
    describe '#is_delayed?' do
      context 'when no phases are delayed' do
        before do
          create(:immo_promo_phase, project: project, end_date: 1.week.from_now, status: 'in_progress')
        end
        
        it 'returns false' do
          expect(project.is_delayed?).to be false
        end
      end
      
      context 'when phases are delayed' do
        before do
          project.update(end_date: 1.month.from_now)
          create(:immo_promo_phase, project: project, end_date: 2.months.from_now, status: 'in_progress')
        end
        
        it 'returns true when phases extend beyond project end date' do
          expect(project.is_delayed?).to be true
        end
      end
    end
    
    describe '#total_surface_area' do
      context 'with lots' do
        before do
          create(:immo_promo_lot, project: project, surface_area: 65.5)
          create(:immo_promo_lot, project: project, surface_area: 75.0)
        end
        
        it 'returns sum of all lots surface area' do
          expect(project.total_surface_area).to eq(140.5)
        end
      end
      
      context 'with no lots' do
        it 'returns 0' do
          expect(project.total_surface_area).to eq(0)
        end
      end
    end
  end
end