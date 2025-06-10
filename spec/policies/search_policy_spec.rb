require 'rails_helper'

RSpec.describe SearchPolicy, type: :policy do
  let(:user) { create(:user) }
  let(:search_query) { create(:search_query, user: user) }
  let(:other_user_query) { create(:search_query, user: create(:user)) }

  subject { described_class }

  permissions ".scope" do
    it "returns all search queries" do
      resolved_scope = subject::Scope.new(user, SearchQuery.all).resolve
      expect(resolved_scope).to include(search_query)
      expect(resolved_scope).to include(other_user_query)
    end
  end

  permissions :index? do
    it "grants access to authenticated users" do
      expect(subject).to permit(user, SearchQuery)
    end

    it "denies access to unauthenticated users" do
      expect(subject).not_to permit(nil, SearchQuery)
    end
  end

  permissions :suggestions? do
    it "grants access to authenticated users" do
      expect(subject).to permit(user, SearchQuery)
    end

    it "denies access to unauthenticated users" do
      expect(subject).not_to permit(nil, SearchQuery)
    end
  end

  describe "#permitted_attributes" do
    let(:policy) { described_class.new(user, search_query) }
    
    it "returns the correct permitted attributes" do
      expect(policy.permitted_attributes).to contain_exactly(:name, :is_favorite, query_params: {})
    end
    
    it "returns the same attributes for all users" do
      other_policy = described_class.new(create(:user), search_query)
      
      expect(other_policy.permitted_attributes).to eq(policy.permitted_attributes)
    end
  end
end