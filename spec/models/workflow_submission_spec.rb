require 'rails_helper'

RSpec.describe WorkflowSubmission, type: :model do
  let(:user) { create(:user) }
  let(:workflow) { create(:workflow) }
  let(:document) { create(:document) }
  
  describe 'associations' do
    it { should belong_to(:workflow) }
    it { should belong_to(:submitted_by).class_name('User') }
    it { should belong_to(:submittable) }
    it { should belong_to(:current_step).class_name('WorkflowStep').optional }
    it { should belong_to(:decided_by).class_name('User').optional }
  end

  describe 'validations' do
    it { should validate_presence_of(:status) }
    it { should validate_inclusion_of(:priority).in_array(%w[low normal high urgent]) }
    
    describe 'uniqueness validation' do
      subject { create(:workflow_submission) }
      it { should validate_uniqueness_of(:workflow_id).scoped_to([:submittable_type, :submittable_id]) }
    end
  end

  describe 'state machine' do
    let(:submission) { create(:workflow_submission) }
    
    it 'starts in pending state' do
      expect(submission.status).to eq('pending')
    end

    describe 'transitions' do
      it 'can transition from pending to in_progress' do
        expect { submission.start! }.to change { submission.status }.from('pending').to('in_progress')
        expect(submission.started_at).to be_present
      end

      it 'can transition from in_progress to waiting_for_approval' do
        submission.start!
        expect { submission.submit_for_approval! }.to change { submission.status }.from('in_progress').to('waiting_for_approval')
      end

      it 'can transition from waiting_for_approval to approved' do
        submission.start!
        submission.submit_for_approval!
        expect { submission.approve! }.to change { submission.status }.from('waiting_for_approval').to('approved')
        expect(submission.decision).to eq('approved')
        expect(submission.decided_at).to be_present
      end

      it 'can transition from waiting_for_approval to rejected' do
        submission.start!
        submission.submit_for_approval!
        expect { submission.reject! }.to change { submission.status }.from('waiting_for_approval').to('rejected')
        expect(submission.decision).to eq('rejected')
        expect(submission.decided_at).to be_present
      end
      
      it 'can transition from waiting_for_approval to returned_for_revision' do
        submission.start!
        submission.submit_for_approval!
        expect { submission.return_for_revision! }.to change { submission.status }.from('waiting_for_approval').to('returned_for_revision')
        expect(submission.decision).to eq('returned_for_revision')
        expect(submission.decided_at).to be_present
      end
      
      it 'can transition from approved to completed' do
        submission.start!
        submission.submit_for_approval!
        submission.approve!
        expect { submission.complete! }.to change { submission.status }.from('approved').to('completed')
        expect(submission.completed_at).to be_present
      end
      
      it 'can be cancelled from various states' do
        expect { submission.cancel! }.to change { submission.status }.from('pending').to('cancelled')
        
        submission2 = create(:workflow_submission)
        submission2.start!
        expect { submission2.cancel! }.to change { submission2.status }.from('in_progress').to('cancelled')
      end
    end
  end

  describe 'scopes' do
    let!(:pending_submission) { create(:workflow_submission, status: 'pending') }
    let!(:in_progress_submission) { create(:workflow_submission, status: 'in_progress') }
    let!(:completed_submission) { create(:workflow_submission, status: 'completed') }

    describe '.pending' do
      it 'returns pending submissions' do
        expect(WorkflowSubmission.pending).to include(pending_submission)
        expect(WorkflowSubmission.pending).not_to include(in_progress_submission, completed_submission)
      end
    end
    
    describe '.in_progress' do
      it 'returns in_progress submissions' do
        expect(WorkflowSubmission.in_progress).to include(in_progress_submission)
        expect(WorkflowSubmission.in_progress).not_to include(pending_submission, completed_submission)
      end
    end

    describe '.completed' do
      it 'returns completed submissions' do
        expect(WorkflowSubmission.completed).to include(completed_submission)
        expect(WorkflowSubmission.completed).not_to include(pending_submission, in_progress_submission)
      end
    end
    
    describe '.overdue' do
      let!(:overdue_submission) { create(:workflow_submission, status: 'in_progress', due_date: 2.days.ago) }
      let!(:not_overdue_submission) { create(:workflow_submission, status: 'in_progress', due_date: 2.days.from_now) }
      
      it 'returns overdue submissions' do
        expect(WorkflowSubmission.overdue).to include(overdue_submission)
        expect(WorkflowSubmission.overdue).not_to include(not_overdue_submission, completed_submission)
      end
    end
    
    describe '.by_priority' do
      before { WorkflowSubmission.destroy_all }
      
      let!(:urgent_submission) { create(:workflow_submission, priority: 'urgent') }
      let!(:high_submission) { create(:workflow_submission, priority: 'high') }
      let!(:normal_submission) { create(:workflow_submission, priority: 'normal') }
      let!(:low_submission) { create(:workflow_submission, priority: 'low') }
      
      it 'orders by priority' do
        expect(WorkflowSubmission.by_priority.to_a).to eq([urgent_submission, high_submission, normal_submission, low_submission])
      end
    end
  end

  describe 'instance methods' do
    let(:submission) { create(:workflow_submission) }
    
    describe '#overdue?' do
      it 'returns false when no due date' do
        submission.due_date = nil
        expect(submission.overdue?).to be false
      end
      
      it 'returns false when due date is in future' do
        submission.due_date = 2.days.from_now
        expect(submission.overdue?).to be false
      end
      
      it 'returns true when due date is past and not completed' do
        submission.due_date = 2.days.ago
        expect(submission.overdue?).to be true
      end
      
      it 'returns false when completed even if past due date' do
        submission.due_date = 2.days.ago
        submission.status = 'completed'
        expect(submission.overdue?).to be false
      end
    end

    describe '#days_until_due' do
      it 'returns nil when no due date' do
        submission.due_date = nil
        expect(submission.days_until_due).to be_nil
      end
      
      it 'returns positive days when due date is in future' do
        submission.due_date = 5.days.from_now
        expect(submission.days_until_due).to eq(5)
      end
      
      it 'returns negative days when due date is past' do
        submission.due_date = 3.days.ago
        expect(submission.days_until_due).to eq(-3)
      end
    end
  end
  
  describe 'callbacks' do
    it 'sets submitted_at on create' do
      submission = WorkflowSubmission.create!(
        workflow: workflow,
        submitted_by: user,
        submittable: document,
        priority: 'normal'
      )
      expect(submission.submitted_at).to be_present
    end
  end
end