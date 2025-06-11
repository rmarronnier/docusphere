require 'rails_helper'

RSpec.describe Documents::Searchable do
  let(:document) { create(:document) }

  describe 'searchkick configuration' do
    it 'configures searchkick with proper options' do
      expect(Document.searchkick_options[:word_start]).to eq([:title, :description])
      expect(Document.searchkick_options[:searchable]).to eq([:title, :description, :content, :metadata_text])
      expect(Document.searchkick_options[:filterable]).to include(:document_type, :document_category, :documentable_type, :created_at, :user_id, :space_id, :tags)
    end
  end

  describe '#search_data' do
    let(:document) { create(:document, :with_tags) }
    
    it 'includes all searchable fields' do
      search_data = document.search_data
      
      expect(search_data).to include(
        :title,
        :description,
        :content,
        :metadata_text,
        :document_type,
        :document_category,
        :documentable_type,
        :created_at,
        :user_id,
        :space_id,
        :tags
      )
    end
    
    it 'includes tag names' do
      search_data = document.search_data
      expect(search_data[:tags]).to eq(document.tags.pluck(:name))
    end

    it 'uses uploaded_by_id for user_id' do
      search_data = document.search_data
      expect(search_data[:user_id]).to eq(document.uploaded_by_id)
    end
  end

  describe '#metadata_text' do
    let(:document) { create(:document) }
    
    it 'returns empty string when no metadata' do
      expect(document.metadata_text).to eq('')
    end
    
    it 'formats metadata as searchable text' do
      document.metadata.create!(key: 'author', value: 'John Doe')
      document.metadata.create!(key: 'category', value: 'Report')
      
      expect(document.metadata_text).to eq('author: John Doe category: Report')
    end
  end
end