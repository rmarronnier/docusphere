require 'rails_helper'

RSpec.describe Documents::Taggable do
  let(:organization) { create(:organization) }
  let(:space) { create(:space, organization: organization) }
  let(:document) { create(:document, space: space) }

  describe 'associations' do
    # Note: association tests require the model class, not the concern module
    # These associations are tested in document_spec.rb
  end

  describe '#tag_list' do
    it 'returns empty string when no tags' do
      expect(document.tag_list).to eq('')
    end
    
    it 'returns comma-separated tag names' do
      tag1 = create(:tag, name: 'important', organization: organization)
      tag2 = create(:tag, name: 'urgent', organization: organization)
      document.tags << [tag1, tag2]
      
      expect(document.tag_list).to eq('important, urgent')
    end
  end

  describe '#tag_list=' do
    it 'creates tags from comma-separated string' do
      expect {
        document.tag_list = 'new, important, document'
      }.to change { Tag.count }.by(3)
      
      expect(document.tags.pluck(:name)).to contain_exactly('new', 'important', 'document')
    end
    
    it 'reuses existing tags' do
      create(:tag, name: 'existing', organization: organization)
      
      expect {
        document.tag_list = 'existing, new'
      }.to change { Tag.count }.by(1)
      
      expect(document.tags.pluck(:name)).to contain_exactly('existing', 'new')
    end
    
    it 'handles duplicate tag names' do
      document.tag_list = 'important, urgent, important'
      expect(document.tags.pluck(:name)).to contain_exactly('important', 'urgent')
    end
    
    it 'strips whitespace from tag names' do
      document.tag_list = ' important , urgent , document '
      expect(document.tags.pluck(:name)).to contain_exactly('important', 'urgent', 'document')
    end
    
    it 'creates tags with correct organization' do
      document.tag_list = 'org-specific'
      tag = document.tags.first
      expect(tag.organization).to eq(organization)
    end
  end
end