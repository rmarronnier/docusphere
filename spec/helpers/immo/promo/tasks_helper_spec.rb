require 'rails_helper'

RSpec.describe Immo::Promo::TasksHelper, type: :helper do
  let(:project) { create(:immo_promo_project) }
  let(:task) { create(:immo_promo_task, project: project) }
  
  describe '#task_priority_badge' do
    it 'displays priority with appropriate styling' do
      expect(helper.task_priority_badge('high')).to have_css('.badge.badge-danger', text: 'High')
      expect(helper.task_priority_badge('medium')).to have_css('.badge.badge-warning', text: 'Medium')
      expect(helper.task_priority_badge('low')).to have_css('.badge.badge-info', text: 'Low')
    end
  end
  
  describe '#task_progress_indicator' do
    it 'shows task completion percentage' do
      task.progress_percentage = 75
      result = helper.task_progress_indicator(task)
      
      expect(result).to have_css('.progress-bar[style*="width: 75%"]')
      expect(result).to have_content('75%')
    end
    
    it 'uses different colors based on status' do
      task.status = 'overdue'
      result = helper.task_progress_indicator(task)
      
      expect(result).to have_css('.progress-bar.bg-danger')
    end
  end
  
  describe '#task_assignee_avatar' do
    let(:stakeholder) { create(:immo_promo_stakeholder, name: 'John Doe') }
    
    before { task.stakeholder = stakeholder }
    
    it 'displays assignee avatar with initials' do
      result = helper.task_assignee_avatar(task)
      
      expect(result).to have_css('.avatar')
      expect(result).to have_content('JD')
      expect(result).to have_css('[title="John Doe"]')
    end
    
    it 'shows unassigned state' do
      task.stakeholder = nil
      result = helper.task_assignee_avatar(task)
      
      expect(result).to have_css('.avatar.avatar-unassigned')
      expect(result).to have_content('?')
    end
  end
  
  describe '#task_duration' do
    it 'formats task duration' do
      task.start_date = Date.current
      task.end_date = 5.days.from_now
      
      expect(helper.task_duration(task)).to eq('5 days')
    end
    
    it 'shows actual vs planned duration' do
      task.start_date = 10.days.ago
      task.end_date = 5.days.ago
      task.actual_end_date = 3.days.ago
      
      result = helper.task_duration(task, show_actual: true)
      expect(result).to include('7 days actual')
      expect(result).to include('5 days planned')
    end
  end
  
  describe '#task_dependencies_summary' do
    before do
      predecessor = create(:immo_promo_task, project: project, name: 'Foundation')
      create(:immo_promo_task_dependency, 
        predecessor_task: predecessor,
        successor_task: task,
        dependency_type: 'finish_to_start'
      )
    end
    
    it 'shows task dependencies' do
      result = helper.task_dependencies_summary(task)
      
      expect(result).to have_content('Depends on: Foundation')
      expect(result).to have_css('.dependency-type', text: 'FS')
    end
  end
  
  describe '#task_checklist_progress' do
    it 'displays checklist completion' do
      task.metadata['checklist'] = [
        { 'item' => 'Review plans', 'completed' => true },
        { 'item' => 'Order materials', 'completed' => true },
        { 'item' => 'Schedule crew', 'completed' => false }
      ]
      
      result = helper.task_checklist_progress(task)
      
      expect(result).to have_content('2/3 completed')
      expect(result).to have_css('.checklist-progress[data-percentage="67"]')
    end
  end
  
  describe '#task_status_timeline' do
    it 'shows task status changes over time' do
      task.metadata['status_history'] = [
        { 'status' => 'pending', 'date' => 5.days.ago.to_s },
        { 'status' => 'in_progress', 'date' => 3.days.ago.to_s },
        { 'status' => 'completed', 'date' => 1.day.ago.to_s }
      ]
      
      result = helper.task_status_timeline(task)
      
      expect(result).to have_css('.timeline-item', count: 3)
      expect(result).to have_content('2 days in progress')
    end
  end
end