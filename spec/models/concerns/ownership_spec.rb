require 'rails_helper'

RSpec.describe Ownership do
  # Create a test class that includes the concern
  let(:test_class) do
    Class.new do
      include ActiveModel::Model
      include Ownership
      
      attr_accessor :user, :uploaded_by, :project_manager
    end
  end
  
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:instance) { test_class.new }
  
  describe '.owned_by' do
    it 'configures ownership attributes' do
      test_class.owned_by :uploaded_by
      expect(test_class.ownership_attributes).to eq([:uploaded_by])
    end
    
    it 'accepts multiple attributes' do
      test_class.owned_by :user, :uploaded_by
      expect(test_class.ownership_attributes).to eq([:user, :uploaded_by])
    end
    
    it 'accepts :none to indicate no ownership' do
      test_class.owned_by :none
      expect(test_class.ownership_attributes).to eq([:none])
    end
  end
  
  describe '.ownership_attributes' do
    it 'defaults to [:user]' do
      expect(test_class.ownership_attributes).to eq([:user])
    end
  end
  
  describe '#owned_by?' do
    context 'with default ownership attribute' do
      before { instance.user = user }
      
      it 'returns true when user matches' do
        expect(instance.owned_by?(user)).to be true
      end
      
      it 'returns false when user does not match' do
        expect(instance.owned_by?(other_user)).to be false
      end
    end
    
    context 'with custom ownership attribute' do
      before do
        test_class.owned_by :uploaded_by
        instance.uploaded_by = user
      end
      
      it 'returns true when user matches custom attribute' do
        expect(instance.owned_by?(user)).to be true
      end
      
      it 'returns false when user does not match' do
        expect(instance.owned_by?(other_user)).to be false
      end
    end
    
    context 'with multiple ownership attributes' do
      before do
        test_class.owned_by :user, :uploaded_by
        instance.user = user
        instance.uploaded_by = other_user
      end
      
      it 'returns true if user matches any attribute' do
        expect(instance.owned_by?(user)).to be true
        expect(instance.owned_by?(other_user)).to be true
      end
    end
    
    context 'with :none ownership' do
      before { test_class.owned_by :none }
      
      it 'always returns false' do
        instance.user = user
        expect(instance.owned_by?(user)).to be false
      end
    end
    
    it 'returns false for nil user' do
      instance.user = user
      expect(instance.owned_by?(nil)).to be false
    end
  end
  
  describe '#owners' do
    context 'with single owner' do
      before do
        test_class.owned_by :uploaded_by
        instance.uploaded_by = user
      end
      
      it 'returns array with the owner' do
        expect(instance.owners).to eq([user])
      end
    end
    
    context 'with multiple owners' do
      before do
        test_class.owned_by :user, :uploaded_by
        instance.user = user
        instance.uploaded_by = other_user
      end
      
      it 'returns array with all owners' do
        expect(instance.owners).to include(user, other_user)
      end
    end
    
    context 'with duplicate owners' do
      before do
        test_class.owned_by :user, :uploaded_by
        instance.user = user
        instance.uploaded_by = user
      end
      
      it 'returns unique owners' do
        expect(instance.owners).to eq([user])
      end
    end
    
    context 'with nil owners' do
      before do
        test_class.owned_by :user, :uploaded_by
        instance.user = nil
        instance.uploaded_by = user
      end
      
      it 'excludes nil values' do
        expect(instance.owners).to eq([user])
      end
    end
  end
  
  describe '#owner' do
    context 'with single owner' do
      before do
        test_class.owned_by :uploaded_by
        instance.uploaded_by = user
      end
      
      it 'returns the owner' do
        expect(instance.owner).to eq(user)
      end
    end
    
    context 'with multiple ownership attributes' do
      before { test_class.owned_by :user, :uploaded_by }
      
      it 'returns the first non-nil owner' do
        instance.user = nil
        instance.uploaded_by = other_user
        expect(instance.owner).to eq(other_user)
      end
      
      it 'prefers first configured attribute' do
        instance.user = user
        instance.uploaded_by = other_user
        expect(instance.owner).to eq(user)
      end
    end
    
    context 'with no owners' do
      before { test_class.owned_by :user }
      
      it 'returns nil' do
        instance.user = nil
        expect(instance.owner).to be_nil
      end
    end
  end
end