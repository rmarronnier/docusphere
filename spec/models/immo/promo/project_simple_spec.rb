require 'rails_helper'

RSpec.describe Immo::Promo::Project, type: :model do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  
  describe 'basic functionality' do
    it 'can be created with valid attributes' do
      project = Immo::Promo::Project.new(
        name: 'Test Project',
        reference: 'TEST-001',
        project_type: 'residential',
        status: 'planning',
        organization: organization,
        start_date: Date.current,
        end_date: Date.current + 1.year
      )
      
      expect(project).to be_valid
    end
    
    it 'validates required fields' do
      project = Immo::Promo::Project.new
      expect(project).not_to be_valid
      expect(project.errors[:name]).to include("ne peut pas être vide")
      expect(project.errors[:reference]).to include("ne peut pas être vide")
    end
    
    it 'validates project_type inclusion' do
      expect {
        Immo::Promo::Project.new(
          name: 'Test',
          reference: 'TEST-001', 
          organization: organization,
          project_type: 'invalid'
        )
      }.to raise_error(ArgumentError, "'invalid' is not a valid project_type")
    end
    
    it 'has correct enum values for project_type' do
      expect(Immo::Promo::Project.project_types.keys).to match_array(%w[residential commercial mixed industrial])
    end
    
    it 'has correct enum values for status' do
      expect(Immo::Promo::Project.statuses.keys).to match_array(%w[planning development construction delivery completed cancelled])
    end
  end
  
  describe 'scopes' do
    let!(:planning_project) { Immo::Promo::Project.create!(name: 'Planning', reference: 'P1', organization: organization, project_type: 'residential', status: 'planning', start_date: Date.current, end_date: Date.current + 1.year) }
    let!(:completed_project) { Immo::Promo::Project.create!(name: 'Completed', reference: 'C1', organization: organization, project_type: 'residential', status: 'completed', start_date: Date.current, end_date: Date.current + 1.year) }
    let!(:residential_project) { Immo::Promo::Project.create!(name: 'Residential', reference: 'R1', organization: organization, project_type: 'residential', status: 'planning', start_date: Date.current, end_date: Date.current + 1.year) }
    let!(:commercial_project) { Immo::Promo::Project.create!(name: 'Commercial', reference: 'COM1', organization: organization, project_type: 'commercial', status: 'planning', start_date: Date.current, end_date: Date.current + 1.year) }

    describe '.active' do
      it 'excludes completed and cancelled projects' do
        active_projects = Immo::Promo::Project.active
        expect(active_projects).to include(planning_project)
        expect(active_projects).not_to include(completed_project)
      end
    end

    describe '.by_type' do
      it 'filters by project type' do
        residential_projects = Immo::Promo::Project.by_type('residential')
        expect(residential_projects).to include(residential_project, planning_project, completed_project)
        expect(residential_projects).not_to include(commercial_project)
      end
    end
  end
  
  describe 'instance methods' do
    let(:project) { Immo::Promo::Project.create!(name: 'Test', reference: 'TEST-001', organization: organization, project_type: 'residential', status: 'planning', start_date: Date.current, end_date: Date.current + 1.year) }
    
    describe '#completion_percentage' do
      it 'returns 0 when no phases exist' do
        expect(project.completion_percentage).to eq(0)
      end
    end
    
    describe '#is_delayed?' do
      it 'returns false when no end_date is set' do
        project.update(end_date: nil)
        expect(project.is_delayed?).to be false
      end
    end
    
    describe '#total_surface_area' do
      it 'returns 0 when no lots exist' do
        expect(project.total_surface_area).to eq(0)
      end
    end
    
    describe '#can_start_construction?' do
      it 'returns false when no construction permits exist' do
        expect(project.can_start_construction?).to be false
      end
    end
  end
  
  describe 'monetization' do
    it 'handles money fields correctly' do
      project = Immo::Promo::Project.create!(
        name: 'Test',
        reference: 'TEST-001',
        organization: organization,
        project_type: 'residential',
        status: 'planning',
        start_date: Date.current,
        end_date: Date.current + 1.year,
        total_budget_cents: 100_000_000
      )
      
      expect(project.total_budget).to be_a(Money)
      expect(project.total_budget.cents).to eq(100_000_000)
      expect(project.total_budget.currency.to_s).to eq('EUR')
    end
  end
end