require 'rails_helper'

RSpec.describe Immo::Promo::ProjectScheduleService do
  let(:organization) { create(:organization) }
  let(:project) do
    create(:immo_promo_project,
      organization: organization,
      start_date: Date.current,
      expected_completion_date: 6.months.from_now
    )
  end
  let(:service) { described_class.new(project) }
  
  describe '#critical_path_analysis' do
    let!(:phase1) do
      create(:immo_promo_phase,
        project: project,
        phase_type: 'studies',
        start_date: Date.current,
        end_date: 1.month.from_now,
        is_critical: true
      )
    end
    
    let!(:phase2) do
      create(:immo_promo_phase,
        project: project,
        phase_type: 'permits',
        start_date: 1.month.from_now,
        end_date: 3.months.from_now
      )
    end
    
    let!(:phase_dependency) do
      create(:immo_promo_phase_dependency,
        dependent_phase: phase2,
        prerequisite_phase: phase1
      )
    end
    
    it 'identifies critical phases' do
      analysis = service.critical_path_analysis
      
      expect(analysis).to be_an(Array)
      expect(analysis).not_to be_empty
      
      critical_phase = analysis.find { |p| p[:phase][:id] == phase1.id }
      expect(critical_phase[:is_on_critical_path]).to be true
    end
    
    it 'calculates slack time' do
      analysis = service.critical_path_analysis
      
      phase_data = analysis.first
      expect(phase_data[:slack_time]).to be_a(Numeric)
    end
    
    it 'includes dependencies' do
      analysis = service.critical_path_analysis
      
      phase2_data = analysis.find { |p| p[:phase][:id] == phase2.id }
      expect(phase2_data[:dependencies]).not_to be_empty
    end
  end
  
  describe '#schedule_alerts' do
    context 'with overdue milestones' do
      let!(:phase) { create(:immo_promo_phase, project: project) }
      let!(:milestone) do
        create(:immo_promo_milestone,
          phase: phase,
          target_date: 1.week.ago,
          status: 'pending',
          is_critical: true
        )
      end
      
      it 'generates overdue milestone alerts' do
        alerts = service.schedule_alerts
        
        milestone_alert = alerts.find { |a| a[:type] == 'overdue_milestone' }
        expect(milestone_alert).to be_present
        expect(milestone_alert[:severity]).to eq('high')
      end
    end
    
    context 'with expiring permits' do
      let!(:permit) do
        create(:immo_promo_permit,
          project: project,
          permit_type: 'construction',
          status: 'approved',
          expiry_date: 2.weeks.from_now
        )
      end
      
      it 'generates permit expiry alerts' do
        alerts = service.schedule_alerts
        
        permit_alert = alerts.find { |a| a[:type] == 'permit_expiry' }
        expect(permit_alert).to be_present
      end
    end
    
    context 'with phase delays' do
      let!(:phase) do
        create(:immo_promo_phase,
          project: project,
          end_date: 1.week.ago,
          status: 'in_progress'
        )
      end
      
      it 'generates phase delay alerts' do
        alerts = service.schedule_alerts
        
        delay_alert = alerts.find { |a| a[:type] == 'phase_delay' }
        expect(delay_alert).to be_present
      end
    end
  end
  
  describe '#timeline_optimization_suggestions' do
    let!(:phases) do
      [
        create(:immo_promo_phase,
          project: project,
          phase_type: 'studies',
          start_date: Date.current,
          end_date: 2.months.from_now
        ),
        create(:immo_promo_phase,
          project: project,
          phase_type: 'permits',
          start_date: 2.months.from_now,
          end_date: 4.months.from_now
        )
      ]
    end
    
    it 'identifies parallelization opportunities' do
      suggestions = service.timeline_optimization_suggestions
      
      expect(suggestions).to be_an(Array)
      parallelization = suggestions.find { |s| s[:type] == 'parallelization' }
      expect(parallelization).to be_present
    end
    
    it 'suggests buffer time additions' do
      # Add tasks to phases to trigger buffer time suggestions
      create(:immo_promo_task, phase: phases.first)
      create(:immo_promo_task, phase: phases.second)
      
      suggestions = service.timeline_optimization_suggestions
      
      buffer_suggestion = suggestions.find { |s| s[:type] == 'buffer_time' }
      expect(buffer_suggestion).to be_present
    end
  end
  
  describe '#calculate_project_delays' do
    context 'with delayed phases' do
      let!(:delayed_phase) do
        create(:immo_promo_phase,
          project: project,
          end_date: 1.week.ago,
          status: 'in_progress'
        )
      end
      
      let!(:on_time_phase) do
        create(:immo_promo_phase,
          project: project,
          end_date: 1.week.from_now,
          status: 'in_progress'
        )
      end
      
      it 'calculates overall delay' do
        delays = service.calculate_project_delays
        
        expect(delays[:overall_delay]).to be > 0
        expect(delays[:delayed_phases]).to have(1).item
      end
      
      it 'identifies impact on completion' do
        delays = service.calculate_project_delays
        
        expect(delays[:impact_on_completion]).to be_present
        expect(delays[:revised_completion_date]).to be > project.expected_completion_date
      end
    end
  end
  
  describe '#reschedule_from_phase' do
    let!(:phases) do
      3.times.map do |i|
        create(:immo_promo_phase,
          project: project,
          start_date: i.months.from_now,
          end_date: (i + 1).months.from_now,
          position: i + 1
        )
      end
    end
    
    let!(:dependencies) do
      phases.each_cons(2) do |prereq, dependent|
        create(:immo_promo_phase_dependency,
          dependent_phase: dependent,
          prerequisite_phase: prereq
        )
      end
    end
    
    it 'cascades schedule changes' do
      new_start = 2.weeks.from_now
      result = service.reschedule_from_phase(phases.first, new_start)
      
      expect(result[:success]).to be true
      expect(result[:rescheduled_phases]).to have(3).items
    end
    
    it 'maintains phase dependencies' do
      new_start = 2.weeks.from_now
      result = service.reschedule_from_phase(phases.first, new_start)
      
      # Reload phases to get updated dates
      phases.each(&:reload)
      
      # Check that phases don't overlap
      phases.each_cons(2) do |phase1, phase2|
        expect(phase2.start_date).to be >= phase1.end_date
      end
    end
  end
  
  describe '#gantt_chart_data' do
    let!(:phases) do
      [
        create(:immo_promo_phase,
          project: project,
          name: 'Studies',
          phase_type: 'studies',
          start_date: Date.current,
          end_date: 1.month.from_now
        ),
        create(:immo_promo_phase,
          project: project,
          name: 'Construction',
          phase_type: 'construction',
          start_date: 1.month.from_now,
          end_date: 4.months.from_now
        )
      ]
    end
    
    let!(:tasks) do
      phases.map do |phase|
        create_list(:immo_promo_task, 2,
          phase: phase,
          start_date: phase.start_date,
          end_date: phase.start_date + 2.weeks
        )
      end.flatten
    end
    
    let!(:milestones) do
      phases.map do |phase|
        create(:immo_promo_milestone,
          phase: phase,
          target_date: phase.end_date,
          name: "#{phase.name} Completion"
        )
      end
    end
    
    it 'generates gantt chart structure' do
      data = service.gantt_chart_data
      
      expect(data).to include(
        :project,
        :phases,
        :milestones,
        :dependencies,
        :critical_path
      )
    end
    
    it 'includes phase hierarchy with tasks' do
      data = service.gantt_chart_data
      
      expect(data[:phases]).to have(2).items
      phase_data = data[:phases].first
      
      expect(phase_data).to include(:phase, :tasks)
      expect(phase_data[:tasks]).to have(2).items
    end
    
    it 'includes milestone data' do
      data = service.gantt_chart_data
      
      expect(data[:milestones]).to have(2).items
      milestone_data = data[:milestones].first
      
      expect(milestone_data).to include(
        :name,
        :date,
        :phase,
        :status
      )
    end
  end
end