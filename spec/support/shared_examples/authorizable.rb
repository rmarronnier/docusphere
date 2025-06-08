RSpec.shared_examples 'authorizable' do
  describe 'authorizable concern' do
    it { is_expected.to have_many(:authorizations).dependent(:destroy) }
    
    describe '#authorize_for' do
      let(:user) { create(:user) }
      let(:permission) { 'read' }
      
      it 'creates an authorization for the user' do
        expect {
          subject.authorize_for(user, permission)
        }.to change { subject.authorizations.count }.by(1)
        
        authorization = subject.authorizations.last
        expect(authorization.user).to eq(user)
        expect(authorization.permission).to eq(permission)
      end
      
      it 'does not create duplicate authorizations' do
        subject.authorize_for(user, permission)
        
        expect {
          subject.authorize_for(user, permission)
        }.not_to change { subject.authorizations.count }
      end
    end
    
    describe '#authorized_for?' do
      let(:user) { create(:user) }
      let(:other_user) { create(:user) }
      
      context 'when user has direct authorization' do
        before { subject.authorize_for(user, 'read') }
        
        it 'returns true for authorized permission' do
          expect(subject.authorized_for?(user, 'read')).to be true
        end
        
        it 'returns false for unauthorized permission' do
          expect(subject.authorized_for?(user, 'write')).to be false
        end
        
        it 'returns false for unauthorized user' do
          expect(subject.authorized_for?(other_user, 'read')).to be false
        end
      end
      
      context 'when user has group authorization' do
        let(:group) { create(:user_group) }
        
        before do
          user.user_groups << group
          subject.authorize_for(group, 'read')
        end
        
        it 'returns true for group member' do
          expect(subject.authorized_for?(user, 'read')).to be true
        end
        
        it 'returns false for non-group member' do
          expect(subject.authorized_for?(other_user, 'read')).to be false
        end
      end
    end
    
    describe '#revoke_authorization_for' do
      let(:user) { create(:user) }
      
      before { subject.authorize_for(user, 'read') }
      
      it 'removes the authorization' do
        expect {
          subject.revoke_authorization_for(user, 'read')
        }.to change { subject.authorizations.count }.by(-1)
        
        expect(subject.authorized_for?(user, 'read')).to be false
      end
    end
    
    describe '#authorized_users' do
      let(:user1) { create(:user) }
      let(:user2) { create(:user) }
      let(:user3) { create(:user) }
      
      before do
        subject.authorize_for(user1, 'read')
        subject.authorize_for(user2, 'read')
        subject.authorize_for(user2, 'write')
      end
      
      it 'returns users with any authorization' do
        expect(subject.authorized_users).to contain_exactly(user1, user2)
      end
      
      it 'returns users with specific permission' do
        expect(subject.authorized_users('read')).to contain_exactly(user1, user2)
        expect(subject.authorized_users('write')).to contain_exactly(user2)
      end
    end
  end
end