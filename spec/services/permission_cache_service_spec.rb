require 'rails_helper'

RSpec.describe PermissionCacheService do
  include ActiveSupport::Testing::TimeHelpers
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:space) { create(:space, organization: organization) }
  let(:document) { create(:document, space: space, uploaded_by: user) }
  let(:user_group) { create(:user_group, organization: organization) }
  
  before do
    # Use memory store for testing cache behavior
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
    Rails.cache.clear
  end
  
  describe '.authorized_for?' do
    context 'when permission is not cached' do
      it 'calculates and caches the permission' do
        document.authorize_user(user, 'read')
        
        # First call should calculate
        expect(document.active_authorizations).to receive(:for_user).and_call_original
        result = described_class.authorized_for?(document, user, 'read')
        expect(result).to be true
        
        # Second call should use cache
        expect(document.active_authorizations).not_to receive(:for_user)
        cached_result = described_class.authorized_for?(document, user, 'read')
        expect(cached_result).to be true
      end
    end
    
    context 'with group permissions' do
      before do
        user_group.add_user(user)
        document.authorize_group(user_group, 'write')
      end
      
      it 'checks group permissions correctly' do
        result = described_class.authorized_for?(document, user, 'write')
        expect(result).to be true
      end
    end
    
    context 'when user has no permission' do
      it 'returns false' do
        result = described_class.authorized_for?(document, user, 'admin')
        expect(result).to be false
      end
    end
  end
  
  describe '.clear_for_user' do
    it 'clears all cached permissions for a user' do
      document.authorize_user(user, 'read')
      
      # Cache the permission
      result1 = described_class.authorized_for?(document, user, 'read')
      expect(result1).to be true
      
      # Clear cache
      described_class.clear_for_user(user)
      
      # The service should still work correctly after cache clear
      result2 = described_class.authorized_for?(document, user, 'read')
      expect(result2).to be true
    end
  end
  
  describe '.clear_for_authorizable' do
    it 'clears all cached permissions for an authorizable' do
      document.authorize_user(user, 'read')
      other_user = create(:user, organization: organization)
      document.authorize_user(other_user, 'write')
      
      # Cache permissions
      described_class.authorized_for?(document, user, 'read')
      described_class.authorized_for?(document, other_user, 'write')
      
      # Clear cache for document
      described_class.clear_for_authorizable(document)
      
      # Both should recalculate
      expect(document.active_authorizations).to receive(:for_user).twice.and_call_original
      described_class.authorized_for?(document, user, 'read')
      described_class.authorized_for?(document, other_user, 'write')
    end
  end
  
  describe 'cache expiration' do
    it 'expires cache after TTL' do
      document.authorize_user(user, 'read')
      
      # Cache the permission
      described_class.authorized_for?(document, user, 'read')
      
      # Travel past TTL
      travel_to (described_class::CACHE_TTL + 1.minute).from_now do
        # Should recalculate
        expect(document.active_authorizations).to receive(:for_user).and_call_original
        described_class.authorized_for?(document, user, 'read')
      end
    end
  end
end