require 'rails_helper'

RSpec.describe Document, type: :model do
  describe 'document locking functionality' do
    let(:organization) { create(:organization) }
    let(:space) { create(:space, organization: organization) }
    let(:owner) { create(:user, organization: organization) }
    let(:other_user) { create(:user, organization: organization) }
    let(:admin_user) { create(:user, organization: organization, role: 'super_admin') }
    let(:document) { create(:document, space: space, uploaded_by: owner, status: 'published') }
    
    describe 'associations' do
      it { is_expected.to belong_to(:locked_by).class_name('User').optional }
    end
    
    describe 'lock state transitions' do
      context 'when document is published' do
        it 'can be locked' do
          expect(document.may_lock?).to be true
          document.lock!
          expect(document.locked?).to be true
        end
        
        it 'sets locked_at when locking' do
          expect {
            document.lock!
          }.to change { document.locked_at }.from(nil)
        end
      end
      
      context 'when document is locked' do
        before { document.lock! }
        
        it 'can be unlocked' do
          expect(document.may_unlock?).to be true
          document.unlock!
          expect(document.published?).to be true
        end
        
        it 'clears lock fields when unlocking' do
          document.locked_by = owner
          document.lock_reason = 'Test reason'
          document.unlock_scheduled_at = 1.day.from_now
          document.save!
          
          document.unlock!
          
          expect(document.locked_by).to be_nil
          expect(document.locked_at).to be_nil
          expect(document.lock_reason).to be_nil
          expect(document.unlock_scheduled_at).to be_nil
        end
      end
    end
    
    describe '#lock_document!' do
      context 'when user can lock' do
        it 'locks the document with user and reason' do
          result = document.lock_document!(owner, reason: 'For editing')
          
          expect(result).to be true
          expect(document).to be_locked
          expect(document.locked_by).to eq(owner)
          expect(document.lock_reason).to eq('For editing')
        end
        
        it 'sets scheduled unlock time' do
          unlock_time = 2.hours.from_now
          document.lock_document!(owner, scheduled_unlock: unlock_time)
          
          expect(document.unlock_scheduled_at).to be_within(1.second).of(unlock_time)
        end
      end
      
      context 'when user cannot lock' do
        it 'returns false if document is already locked' do
          document.lock!
          
          result = document.lock_document!(owner)
          expect(result).to be false
        end
      end
    end
    
    describe '#unlock_document!' do
      before do
        document.lock_document!(owner, reason: 'Test lock')
      end
      
      context 'when user can unlock' do
        it 'unlocks the document when requested by lock owner' do
          result = document.unlock_document!(owner)
          
          expect(result).to be true
          expect(document).to be_published
          expect(document.locked_by).to be_nil
        end
        
        it 'unlocks the document when requested by admin' do
          result = document.unlock_document!(admin_user)
          
          expect(result).to be true
          expect(document).to be_published
        end
      end
      
      context 'when user cannot unlock' do
        it 'returns false for other users' do
          result = document.unlock_document!(other_user)
          
          expect(result).to be false
          expect(document).to be_locked
        end
      end
    end
    
    describe '#can_lock?' do
      context 'when document is not locked' do
        it 'returns true for owner' do
          expect(document.can_lock?(owner)).to be true
        end
        
        it 'returns true for admin' do
          expect(document.can_lock?(admin_user)).to be true
        end
        
        it 'returns true for user with write permission' do
          document.authorize_user(other_user, 'write', granted_by: owner)
          expect(document.can_lock?(other_user)).to be true
        end
        
        it 'returns false for user without permission' do
          expect(document.can_lock?(other_user)).to be false
        end
      end
      
      context 'when document is locked' do
        before { document.lock! }
        
        it 'returns false even for owner' do
          expect(document.can_lock?(owner)).to be false
        end
      end
    end
    
    describe '#can_unlock?' do
      context 'when document is not locked' do
        it 'returns false' do
          expect(document.can_unlock?(owner)).to be false
        end
      end
      
      context 'when document is locked' do
        before { document.lock_document!(owner) }
        
        it 'returns true for the user who locked it' do
          expect(document.can_unlock?(owner)).to be true
        end
        
        it 'returns true for document owner' do
          document.lock_document!(other_user)
          expect(document.can_unlock?(owner)).to be true
        end
        
        it 'returns true for admin' do
          expect(document.can_unlock?(admin_user)).to be true
        end
        
        it 'returns false for other users' do
          expect(document.can_unlock?(other_user)).to be false
        end
      end
    end
    
    describe '#locked_by_user?' do
      it 'returns true when locked by the specified user' do
        document.lock_document!(owner)
        expect(document.locked_by_user?(owner)).to be true
      end
      
      it 'returns false when locked by different user' do
        document.lock_document!(owner)
        expect(document.locked_by_user?(other_user)).to be false
      end
      
      it 'returns false when not locked' do
        expect(document.locked_by_user?(owner)).to be false
      end
    end
    
    describe '#lock_expired?' do
      context 'when document is not locked' do
        it 'returns false' do
          expect(document.lock_expired?).to be false
        end
      end
      
      context 'when document is locked' do
        before { document.lock_document!(owner) }
        
        it 'returns false when no scheduled unlock' do
          expect(document.lock_expired?).to be false
        end
        
        it 'returns false when scheduled unlock is in future' do
          document.update!(unlock_scheduled_at: 1.hour.from_now)
          expect(document.lock_expired?).to be false
        end
        
        it 'returns true when scheduled unlock is in past' do
          document.update!(unlock_scheduled_at: 1.hour.ago)
          expect(document.lock_expired?).to be true
        end
      end
    end
    
    describe '#editable_by?' do
      context 'when document is not locked' do
        it 'returns true for users with write permission' do
          document.authorize_user(other_user, 'write', granted_by: owner)
          expect(document.editable_by?(other_user)).to be true
        end
      end
      
      context 'when document is locked' do
        before { document.lock_document!(owner) }
        
        it 'returns true for the user who locked it' do
          expect(document.editable_by?(owner)).to be true
        end
        
        it 'returns false for other users even with write permission' do
          document.authorize_user(other_user, 'write', granted_by: owner)
          expect(document.editable_by?(other_user)).to be false
        end
      end
    end
  end
end