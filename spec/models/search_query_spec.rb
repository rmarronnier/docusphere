require 'rails_helper'

RSpec.describe SearchQuery, type: :model do
  let(:user) { create(:user) }
  
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:query) }
    it { should validate_presence_of(:user) }
    
    it 'validates query length' do
      should validate_length_of(:query).is_at_least(1).is_at_most(500)
    end
  end

  describe 'scopes' do
    let!(:recent_query) { create(:search_query, created_at: 1.day.ago, user: user) }
    let!(:old_query) { create(:search_query, created_at: 1.month.ago, user: user) }

    describe '.recent' do
      it 'returns queries from last 30 days' do
        expect(SearchQuery.recent).to include(recent_query)
        expect(SearchQuery.recent).not_to include(old_query)
      end
    end

    describe '.popular' do
      before do
        create_list(:search_query, 3, query: 'popular term', user: user)
        create(:search_query, query: 'rare term', user: user)
      end

      it 'returns most frequent queries' do
        popular_queries = SearchQuery.popular.limit(1)
        expect(popular_queries.first.query).to eq('popular term')
      end
    end
  end

  describe 'instance methods' do
    let(:search_query) { create(:search_query, query: 'test query', user: user) }
    
    describe '#normalized_query' do
      it 'returns downcased and stripped query' do
        search_query.update(query: '  TEST QUERY  ')
        expect(search_query.normalized_query).to eq('test query')
      end
    end
  end

  describe 'callbacks' do
    it 'stores query parameters as JSON' do
      params = { term: 'test', category: 'document' }
      query = SearchQuery.create!(name: 'Test Query', query_params: params, user: user)
      expect(query.query_params).to eq(params.stringify_keys)
    end
  end
end