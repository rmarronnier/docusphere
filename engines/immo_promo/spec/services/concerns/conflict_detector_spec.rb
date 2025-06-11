require 'rails_helper'

RSpec.describe Immo::Promo::Concerns::ConflictDetector do
  # Create a test class that includes the concern
  let(:test_class) do
    Class.new do
      include Immo::Promo::Concerns::ConflictDetector
      attr_reader :project
      
      def initialize(project)
        @project = project
      end
    end
  end
  
  let(:service) { test_class.new(project) }
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  
  describe '#detect_conflicts' do
    it 'returns all types of conflicts' do
      result = service.detect_conflicts
      
      expect(result).to have_key(:resource_conflicts)
      expect(result).to have_key(:dependency_conflicts)
      expect(result).to have_key(:certification_conflicts)
    end
  end
  
  describe '#active_interventions' do
    let!(:phase) { create(:immo_promo_phase, project: project) }
    let!(:active_task) { create(:immo_promo_task, 
      phase: phase,
      status: 'in_progress',
      start_date: 1.week.ago,
      end_date: 1.week.from_now
    )}
    let!(:future_task) { create(:immo_promo_task, 
      phase: phase,
      status: 'pending',
      start_date: 1.month.from_now,
      end_date: 2.months.from_now
    )}
    
    it 'returns only currently active tasks' do
      tasks = service.active_interventions
      
      expect(tasks).to include(active_task)
      expect(tasks).not_to include(future_task)
    end
  end
  
  describe '#upcoming_interventions' do
    let!(:phase) { create(:immo_promo_phase, project: project) }
    let!(:upcoming_task) { create(:immo_promo_task, 
      phase: phase,
      status: 'pending',
      start_date: 1.week.from_now,
      end_date: 2.weeks.from_now
    )}
    let!(:far_future_task) { create(:immo_promo_task, 
      phase: phase,
      status: 'pending',
      start_date: 1.month.from_now,
      end_date: 2.months.from_now
    )}
    
    it 'returns tasks starting within 2 weeks' do
      tasks = service.upcoming_interventions
      
      expect(tasks).to include(upcoming_task)
      expect(tasks).not_to include(far_future_task)
    end
  end
  
  describe 'private methods' do
    describe '#find_resource_conflicts' do
      let(:stakeholder) { create(:immo_promo_stakeholder, project: project) }
      let!(:task1) { create(:immo_promo_task, 
        stakeholder: stakeholder,
        start_date: 1.week.from_now,
        end_date: 2.weeks.from_now,
        status: 'pending'
      )}
      let!(:task2) { create(:immo_promo_task, 
        stakeholder: stakeholder,
        start_date: 10.days.from_now,
        end_date: 3.weeks.from_now,
        status: 'pending'
      )}
      
      it 'identifies double booking conflicts' do
        conflicts = service.send(:find_resource_conflicts)
        
        expect(conflicts).not_to be_empty
        conflict = conflicts.first
        expect(conflict[:type]).to eq('double_booking')
        expect(conflict[:stakeholder]).to eq(stakeholder)
        expect(conflict[:tasks]).to include(task1, task2)
      end
    end
    
    describe '#find_certification_conflicts' do
      let(:stakeholder) { create(:immo_promo_stakeholder, project: project) }
      let(:phase) { create(:immo_promo_phase, project: project) }
      let!(:task) { create(:immo_promo_task, 
        phase: phase,
        stakeholder: stakeholder
      )}
      
      before do
        # Mock required_skills on task
        allow(task).to receive(:required_skills).and_return(['electrical_certification', 'safety_certification'])
        allow(stakeholder.certifications).to receive(:pluck).with(:certification_type)
          .and_return(['safety_certification'])
      end
      
      it 'identifies missing certification conflicts' do
        allow(project).to receive(:tasks).and_return([task])
        
        conflicts = service.send(:find_certification_conflicts)
        
        expect(conflicts).not_to be_empty
        conflict = conflicts.first
        expect(conflict[:type]).to eq('missing_certification')
        expect(conflict[:task]).to eq(task)
        expect(conflict[:stakeholder]).to eq(stakeholder)
        expect(conflict[:missing]).to include('electrical_certification')
      end
    end
    
    describe '#find_overlapping_tasks' do
      let(:stakeholder) { create(:immo_promo_stakeholder, project: project) }
      
      context 'with overlapping tasks' do
        let!(:task1) { create(:immo_promo_task, 
          stakeholder: stakeholder,
          start_date: Date.today,
          end_date: 1.week.from_now,
          status: 'pending'
        )}
        let!(:task2) { create(:immo_promo_task, 
          stakeholder: stakeholder,
          start_date: 3.days.from_now,
          end_date: 2.weeks.from_now,
          status: 'pending'
        )}
        let!(:task3) { create(:immo_promo_task, 
          stakeholder: stakeholder,
          start_date: 3.weeks.from_now,
          end_date: 4.weeks.from_now,
          status: 'pending'
        )}
        
        it 'finds overlapping task pairs' do
          overlapping = service.send(:find_overlapping_tasks, stakeholder)
          
          expect(overlapping.size).to eq(1)
          expect(overlapping.first).to match_array([task1, task2])
        end
      end
      
      context 'with no overlapping tasks' do
        let!(:task1) { create(:immo_promo_task, 
          stakeholder: stakeholder,
          start_date: Date.today,
          end_date: 1.week.from_now,
          status: 'pending'
        )}
        let!(:task2) { create(:immo_promo_task, 
          stakeholder: stakeholder,
          start_date: 2.weeks.from_now,
          end_date: 3.weeks.from_now,
          status: 'pending'
        )}
        
        it 'returns empty array' do
          overlapping = service.send(:find_overlapping_tasks, stakeholder)
          expect(overlapping).to be_empty
        end
      end
    end
    
    describe '#tasks_overlap?' do
      it 'detects partial overlap' do
        task1 = build(:immo_promo_task, 
          start_date: Date.today,
          end_date: 1.week.from_now
        )
        task2 = build(:immo_promo_task, 
          start_date: 3.days.from_now,
          end_date: 2.weeks.from_now
        )
        
        expect(service.send(:tasks_overlap?, task1, task2)).to be true
      end
      
      it 'detects complete overlap' do
        task1 = build(:immo_promo_task, 
          start_date: Date.today,
          end_date: 2.weeks.from_now
        )
        task2 = build(:immo_promo_task, 
          start_date: 1.week.from_now,
          end_date: 10.days.from_now
        )
        
        expect(service.send(:tasks_overlap?, task1, task2)).to be true
      end
      
      it 'detects edge case overlap' do
        task1 = build(:immo_promo_task, 
          start_date: Date.today,
          end_date: 1.week.from_now
        )
        task2 = build(:immo_promo_task, 
          start_date: 1.week.from_now,
          end_date: 2.weeks.from_now
        )
        
        expect(service.send(:tasks_overlap?, task1, task2)).to be true
      end
      
      it 'returns false for non-overlapping tasks' do
        task1 = build(:immo_promo_task, 
          start_date: Date.today,
          end_date: 1.week.from_now
        )
        task2 = build(:immo_promo_task, 
          start_date: 2.weeks.from_now,
          end_date: 3.weeks.from_now
        )
        
        expect(service.send(:tasks_overlap?, task1, task2)).to be false
      end
    end
  end
end