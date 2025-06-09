require 'rails_helper'

RSpec.describe DocumentShare, type: :model do
  describe 'associations' do
    it { should belong_to(:document) }
    it { should belong_to(:shared_by).class_name('User') }
    it { should belong_to(:shared_with).class_name('User').optional }
  end

  describe 'validations' do
    it { should validate_inclusion_of(:access_level).in_array(%w[read write admin]) }

    context 'when shared_with is present' do
      subject { build(:document_share, shared_with: create(:user)) }
      it { should_not validate_presence_of(:email) }
    end

    context 'when shared_with is not present' do
      subject { build(:document_share, shared_with: nil) }
      it { should validate_presence_of(:email) }
    end

    context 'when email is present' do
      subject { build(:document_share, email: 'test@example.com') }
      it { should_not validate_presence_of(:shared_with) }
    end

    context 'when email is not present' do
      subject { build(:document_share, email: nil) }
      it { should validate_presence_of(:shared_with) }
    end
  end

  describe 'callbacks' do
    describe 'before_create' do
      it 'generates an access token' do
        document_share = build(:document_share)
        expect(document_share.access_token).to be_nil
        document_share.save!
        expect(document_share.access_token).to be_present
        expect(document_share.access_token.length).to be >= 32
      end
    end
  end

  describe 'scopes' do
    let!(:active_share) { create(:document_share, is_active: true, expires_at: nil) }
    let!(:active_with_future_expiry) { create(:document_share, is_active: true, expires_at: 1.day.from_now) }
    let!(:expired_share) { create(:document_share, is_active: true, expires_at: 1.day.ago) }
    let!(:inactive_share) { create(:document_share, is_active: false) }

    describe '.active' do
      it 'returns only active shares that are not expired' do
        expect(DocumentShare.active).to contain_exactly(active_share, active_with_future_expiry)
      end
    end

    describe '.expired' do
      it 'returns only expired shares' do
        expect(DocumentShare.expired).to contain_exactly(expired_share)
      end
    end
  end

  describe 'instance methods' do
    describe '#expired?' do
      context 'when expires_at is nil' do
        let(:document_share) { build(:document_share, expires_at: nil) }

        it 'returns false' do
          expect(document_share.expired?).to be false
        end
      end

      context 'when expires_at is in the future' do
        let(:document_share) { build(:document_share, expires_at: 1.day.from_now) }

        it 'returns false' do
          expect(document_share.expired?).to be false
        end
      end

      context 'when expires_at is in the past' do
        let(:document_share) { build(:document_share, expires_at: 1.day.ago) }

        it 'returns true' do
          expect(document_share.expired?).to be true
        end
      end
    end

    describe '#active?' do
      context 'when is_active is true and not expired' do
        let(:document_share) { build(:document_share, is_active: true, expires_at: nil) }

        it 'returns true' do
          expect(document_share.active?).to be true
        end
      end

      context 'when is_active is false' do
        let(:document_share) { build(:document_share, is_active: false) }

        it 'returns false' do
          expect(document_share.active?).to be false
        end
      end

      context 'when is_active is true but expired' do
        let(:document_share) { build(:document_share, is_active: true, expires_at: 1.day.ago) }

        it 'returns false' do
          expect(document_share.active?).to be false
        end
      end
    end

    describe '#revoke!' do
      let(:document_share) { create(:document_share, is_active: true) }

      it 'sets is_active to false' do
        expect { document_share.revoke! }.to change { document_share.is_active }.from(true).to(false)
      end
    end
  end
end