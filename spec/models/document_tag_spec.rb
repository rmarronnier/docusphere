require 'rails_helper'

RSpec.describe DocumentTag, type: :model do
  describe 'associations' do
    it { should belong_to(:document) }
    it { should belong_to(:tag) }
  end

  describe 'validations' do
    subject { create(:document_tag) }
    
    it { should validate_uniqueness_of(:document_id).scoped_to(:tag_id) }
  end
end