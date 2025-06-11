require 'rails_helper'

RSpec.describe Documents::Lockable do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:document) { create(:document) }

  describe 'locking functionality' do
    describe '#lock!' do
      it 'locks the document for a user' do
        expect(document.locked?).to be false
        document.lock!(user)
        expect(document.locked?).to be true
        expect(document.locked_by).to eq(user)
      end

      it 'sets lock timestamp' do
        document.lock!(user)
        expect(document.locked_at).to be_present
      end

      it 'sets default unlock time (4 hours)' do
        document.lock!(user)
        expect(document.unlock_scheduled_at).to be_within(1.second).of(4.hours.from_now)
      end

      it 'accepts custom duration' do
        document.lock!(user, duration: 2.hours)
        expect(document.unlock_scheduled_at).to be_within(1.second).of(2.hours.from_now)
      end

      it 'prevents locking when already locked by another user' do
        document.lock!(user)
        expect { document.lock!(other_user) }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'allows same user to refresh lock' do
        document.lock!(user)
        original_unlock_time = document.unlock_scheduled_at
        
        travel 1.hour do
          document.lock!(user)
          expect(document.unlock_scheduled_at).to be > original_unlock_time
        end
      end
    end

    describe '#unlock!' do
      before { document.lock!(user) }

      it 'unlocks the document' do
        document.unlock!
        expect(document.locked?).to be false
        expect(document.locked_by).to be_nil
        expect(document.locked_at).to be_nil
        expect(document.unlock_scheduled_at).to be_nil
      end

      it 'can be unlocked by the lock owner' do
        expect { document.unlock!(user) }.not_to raise_error
        expect(document.locked?).to be false
      end

      it 'cannot be unlocked by another user' do
        expect { document.unlock!(other_user) }.to raise_error(RuntimeError, /not authorized/)
        expect(document.locked?).to be true
      end
    end

    describe '#locked?' do
      it 'returns false when not locked' do
        expect(document.locked?).to be false
      end

      it 'returns true when locked' do
        document.lock!(user)
        expect(document.locked?).to be true
      end

      it 'returns false when lock expired' do
        document.lock!(user, duration: 1.second)
        travel 2.seconds do
          expect(document.locked?).to be false
        end
      end
    end

    describe '#locked_by?' do
      it 'returns false when not locked' do
        expect(document.locked_by?(user)).to be false
      end

      it 'returns true when locked by the user' do
        document.lock!(user)
        expect(document.locked_by?(user)).to be true
      end

      it 'returns false when locked by another user' do
        document.lock!(user)
        expect(document.locked_by?(other_user)).to be false
      end
    end

    describe '#can_be_edited_by?' do
      it 'returns true when not locked' do
        expect(document.can_be_edited_by?(user)).to be true
      end

      it 'returns true when locked by the same user' do
        document.lock!(user)
        expect(document.can_be_edited_by?(user)).to be true
      end

      it 'returns false when locked by another user' do
        document.lock!(user)
        expect(document.can_be_edited_by?(other_user)).to be false
      end
    end

    describe '#lock_status' do
      it 'returns unlocked status when not locked' do
        status = document.lock_status
        expect(status[:locked]).to be false
        expect(status[:locked_by]).to be_nil
      end

      it 'returns locked status with details' do
        document.lock!(user)
        status = document.lock_status
        
        expect(status[:locked]).to be true
        expect(status[:locked_by]).to eq(user.full_name)
        expect(status[:locked_at]).to eq(document.locked_at)
        expect(status[:unlock_scheduled_at]).to eq(document.unlock_scheduled_at)
      end
    end

    describe 'auto-unlock scope' do
      let!(:expired_lock) do
        doc = create(:document)
        doc.lock!(user, duration: 1.second)
        doc
      end

      let!(:valid_lock) do
        doc = create(:document)
        doc.lock!(user, duration: 1.hour)
        doc
      end

      it 'finds documents with expired locks' do
        travel 2.seconds do
          expect(Document.with_expired_locks).to include(expired_lock)
          expect(Document.with_expired_locks).not_to include(valid_lock)
        end
      end
    end
  end
end