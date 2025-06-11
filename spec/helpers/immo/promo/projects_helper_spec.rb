require 'rails_helper'

RSpec.describe Immo::Promo::ProjectsHelper, type: :helper do
  let(:project) { create(:immo_promo_project) }
  
  describe '#project_status_badge' do
    it 'returns appropriate badge for project status' do
      project.status = 'in_progress'
      result = helper.project_status_badge(project)
      
      expect(result).to have_css('.badge.badge-primary')
      expect(result).to have_content('In Progress')
    end
    
    it 'handles different statuses with correct styling' do
      expect(helper.project_status_badge(project.tap { |p| p.status = 'planning' }))
        .to have_css('.badge-secondary')
      expect(helper.project_status_badge(project.tap { |p| p.status = 'completed' }))
        .to have_css('.badge-success')
      expect(helper.project_status_badge(project.tap { |p| p.status = 'on_hold' }))
        .to have_css('.badge-warning')
    end
  end
  
  describe '#project_progress_bar' do
    it 'displays project completion percentage' do
      project.metadata['completion_percentage'] = 75
      result = helper.project_progress_bar(project)
      
      expect(result).to have_css('.progress-bar[style*="width: 75%"]')
      expect(result).to have_content('75%')
    end
    
    it 'handles zero progress' do
      project.metadata['completion_percentage'] = 0
      result = helper.project_progress_bar(project)
      
      expect(result).to have_css('.progress-bar[style*="width: 0%"]')
    end
  end
  
  describe '#format_project_budget' do
    it 'formats project budget with currency' do
      project.total_budget_cents = 5_000_000_00
      
      expect(helper.format_project_budget(project)).to eq('€50,000.00')
    end
    
    it 'shows budget vs actual when available' do
      project.total_budget_cents = 5_000_000_00
      project.metadata['actual_spent_cents'] = 4_500_000_00
      
      result = helper.format_project_budget(project, show_actual: true)
      expect(result).to include('€45,000.00 / €50,000.00')
    end
  end
  
  describe '#project_timeline_status' do
    it 'shows on-time status' do
      project.end_date = 1.month.from_now
      result = helper.project_timeline_status(project)
      
      expect(result).to have_css('.text-success')
      expect(result).to have_content('On Schedule')
    end
    
    it 'shows delayed status' do
      project.end_date = 1.week.ago
      project.status = 'in_progress'
      result = helper.project_timeline_status(project)
      
      expect(result).to have_css('.text-danger')
      expect(result).to have_content('Delayed')
    end
  end
  
  describe '#project_team_summary' do
    before do
      create_list(:immo_promo_stakeholder, 3, project: project, stakeholder_type: 'contractor')
      create_list(:immo_promo_stakeholder, 2, project: project, stakeholder_type: 'architect')
    end
    
    it 'summarizes project team composition' do
      result = helper.project_team_summary(project)
      
      expect(result).to have_content('5 team members')
      expect(result).to have_content('3 contractors')
      expect(result).to have_content('2 architects')
    end
  end
  
  describe '#project_risk_indicator' do
    it 'shows risk level with appropriate styling' do
      create_list(:immo_promo_risk, 2, project: project, severity: 'high', status: 'active')
      
      result = helper.project_risk_indicator(project)
      
      expect(result).to have_css('.risk-indicator.risk-high')
      expect(result).to have_content('2 active risks')
    end
  end
  
  describe '#project_phase_pills' do
    before do
      create(:immo_promo_phase, project: project, name: 'Design', status: 'completed')
      create(:immo_promo_phase, project: project, name: 'Construction', status: 'in_progress')
      create(:immo_promo_phase, project: project, name: 'Finishing', status: 'pending')
    end
    
    it 'displays phases as pills with status' do
      result = helper.project_phase_pills(project)
      
      expect(result).to have_css('.phase-pill.completed', text: 'Design')
      expect(result).to have_css('.phase-pill.in-progress', text: 'Construction')
      expect(result).to have_css('.phase-pill.pending', text: 'Finishing')
    end
  end
  
  describe '#project_quick_stats' do
    it 'displays key project metrics' do
      result = helper.project_quick_stats(project)
      
      expect(result).to have_css('.stat-item')
      expect(result).to have_content('Budget')
      expect(result).to have_content('Timeline')
      expect(result).to have_content('Completion')
    end
  end
end