require 'rails_helper'

RSpec.describe Immo::Promo::CoordinationHelper, type: :helper do
  let(:project) { create(:immo_promo_project) }
  
  describe '#planning_calendar' do
    let(:tasks) do
      [
        create(:immo_promo_task, project: project, start_date: Date.current, end_date: 3.days.from_now),
        create(:immo_promo_task, project: project, start_date: 2.days.from_now, end_date: 5.days.from_now)
      ]
    end
    
    it 'renders calendar view with tasks' do
      result = helper.planning_calendar(tasks, month: Date.current)
      
      expect(result).to have_css('.planning-calendar')
      expect(result).to have_css('.calendar-task', count: 2)
      expect(result).to have_css('.calendar-header')
    end
    
    it 'highlights conflicts' do
      tasks.first.metadata['has_conflict'] = true
      
      result = helper.planning_calendar(tasks)
      
      expect(result).to have_css('.calendar-task.conflict')
    end
  end
  
  describe '#resource_allocation_matrix' do
    let(:stakeholders) { create_list(:immo_promo_stakeholder, 3, project: project) }
    let(:phases) { create_list(:immo_promo_phase, 2, project: project) }
    
    before do
      stakeholders.each do |stakeholder|
        phases.each do |phase|
          create(:immo_promo_task, 
            stakeholder: stakeholder, 
            phase: phase,
            start_date: phase.start_date,
            end_date: phase.start_date + 10.days
          )
        end
      end
    end
    
    it 'displays resource allocation grid' do
      result = helper.resource_allocation_matrix(project)
      
      expect(result).to have_css('.allocation-matrix')
      expect(result).to have_css('.resource-row', count: 3)
      expect(result).to have_css('.phase-column', count: 2)
    end
    
    it 'shows workload indicators' do
      result = helper.resource_allocation_matrix(project)
      
      expect(result).to have_css('.workload-indicator')
      expect(result).to have_css('[data-workload]')
    end
  end
  
  describe '#task_dependencies_graph' do
    let(:tasks) do
      task1 = create(:immo_promo_task, project: project, name: 'Foundation')
      task2 = create(:immo_promo_task, project: project, name: 'Structure')
      task3 = create(:immo_promo_task, project: project, name: 'Roofing')
      
      create(:immo_promo_task_dependency, 
        predecessor_task: task1,
        successor_task: task2,
        dependency_type: 'finish_to_start'
      )
      create(:immo_promo_task_dependency,
        predecessor_task: task2,
        successor_task: task3,
        dependency_type: 'finish_to_start'
      )
      
      [task1, task2, task3]
    end
    
    it 'renders dependency network' do
      result = helper.task_dependencies_graph(tasks)
      
      expect(result).to have_css('.dependency-graph')
      expect(result).to have_css('.task-node', count: 3)
      expect(result).to have_css('.dependency-link', count: 2)
    end
    
    it 'identifies critical path' do
      result = helper.task_dependencies_graph(tasks)
      
      expect(result).to have_css('.critical-path')
    end
  end
  
  describe '#conflict_resolution_panel' do
    let(:conflicts) do
      [
        {
          type: 'resource_overallocation',
          stakeholder: create(:immo_promo_stakeholder),
          tasks: create_list(:immo_promo_task, 2),
          severity: 'high'
        },
        {
          type: 'schedule_overlap',
          tasks: create_list(:immo_promo_task, 2),
          severity: 'medium'
        }
      ]
    end
    
    it 'displays conflicts with severity' do
      result = helper.conflict_resolution_panel(conflicts)
      
      expect(result).to have_css('.conflict-item', count: 2)
      expect(result).to have_css('.severity-high')
      expect(result).to have_css('.severity-medium')
    end
    
    it 'provides resolution actions' do
      result = helper.conflict_resolution_panel(conflicts)
      
      expect(result).to have_css('.resolution-actions')
      expect(result).to have_button('Resolve')
    end
  end
  
  describe '#milestone_tracker' do
    let(:milestones) do
      [
        create(:immo_promo_milestone, project: project, due_date: 1.week.from_now, status: 'pending'),
        create(:immo_promo_milestone, project: project, due_date: 1.month.ago, status: 'completed'),
        create(:immo_promo_milestone, project: project, due_date: 1.day.ago, status: 'overdue')
      ]
    end
    
    it 'displays milestone progress' do
      result = helper.milestone_tracker(milestones)
      
      expect(result).to have_css('.milestone', count: 3)
      expect(result).to have_css('.milestone-pending')
      expect(result).to have_css('.milestone-completed')
      expect(result).to have_css('.milestone-overdue')
    end
    
    it 'shows time until due' do
      result = helper.milestone_tracker(milestones)
      
      expect(result).to have_content('Due in 7 days')
      expect(result).to have_content('Overdue by 1 day')
    end
  end
  
  describe '#team_communication_feed' do
    it 'displays recent team activities' do
      activities = [
        { type: 'task_completed', user: 'John Doe', task: 'Foundation work', time: 1.hour.ago },
        { type: 'comment_added', user: 'Jane Smith', message: 'Weather delay expected', time: 3.hours.ago },
        { type: 'file_uploaded', user: 'Bob Wilson', file: 'Plans v2.pdf', time: 1.day.ago }
      ]
      
      result = helper.team_communication_feed(activities)
      
      expect(result).to have_css('.activity-item', count: 3)
      expect(result).to have_css('.activity-task_completed')
      expect(result).to have_css('.activity-comment_added')
      expect(result).to have_css('.activity-file_uploaded')
    end
  end
  
  describe '#phase_progress_overview' do
    before do
      phases = create_list(:immo_promo_phase, 3, project: project)
      phases[0].update!(progress_percentage: 100, status: 'completed')
      phases[1].update!(progress_percentage: 60, status: 'in_progress')
      phases[2].update!(progress_percentage: 0, status: 'pending')
    end
    
    it 'shows phase completion status' do
      result = helper.phase_progress_overview(project)
      
      expect(result).to have_css('.phase-progress', count: 3)
      expect(result).to have_css('.progress-bar[style*="width: 100%"]')
      expect(result).to have_css('.progress-bar[style*="width: 60%"]')
      expect(result).to have_css('.progress-bar[style*="width: 0%"]')
    end
  end
  
  describe '#coordination_alerts' do
    it 'displays urgent coordination issues' do
      alerts = [
        { type: 'deadline_approaching', message: 'Permit deadline in 2 days', level: 'warning' },
        { type: 'resource_conflict', message: 'Architect double-booked', level: 'danger' },
        { type: 'dependency_blocked', message: 'Foundation inspection pending', level: 'info' }
      ]
      
      result = helper.coordination_alerts(alerts)
      
      expect(result).to have_css('.alert', count: 3)
      expect(result).to have_css('.alert-warning')
      expect(result).to have_css('.alert-danger')
      expect(result).to have_css('.alert-info')
    end
  end
end