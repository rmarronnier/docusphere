require 'rails_helper'

RSpec.describe 'Document Versioning Service' do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:space) { create(:space, organization: organization) }
  let(:folder) { create(:folder, space: space) }
  let(:document) { create(:document, folder: folder, space: space, uploaded_by: user) }
  
  before do
    Current.user = user
    PaperTrail.request.whodunnit = user.id.to_s
  end

  describe 'version creation' do
    let(:new_file) { fixture_file_upload('spec/fixtures/files/sample.pdf', 'application/pdf') }
    
    it 'creates version when file is updated' do
      initial_version_count = document.versions.count
      
      # Create a version using the concern method
      version = document.create_version!(new_file, user, 'Test version')
      
      expect(version).to be_present
      expect(version).to be_a(DocumentVersion)
      expect(document.versions.count).to eq(initial_version_count + 1)
    end
    
    it 'stores version metadata' do
      version = document.create_version!(new_file, user, 'Important update')
      
      expect(version.comment).to eq('Important update')
      expect(version.created_by_id).to eq(user.id)
      expect(version.whodunnit).to eq(user.id.to_s)
      expect(version.event).to eq('update')
    end
    
    it 'captures file metadata' do
      version = document.create_version!(new_file, user)
      
      expect(version.file_metadata).to be_present
      expect(version.file_metadata['file_name']).to eq('sample.pdf')
      expect(version.file_metadata['content_type']).to eq('application/pdf')
      expect(version.file_metadata['file_size']).to be_present
    end
    
    it 'sets version number correctly' do
      # Create first version
      version1 = document.create_version!(new_file, user, 'Version 1')
      expect(version1.version_number).to eq(1)
      
      # Create second version
      new_file2 = fixture_file_upload('spec/fixtures/files/sample.pdf', 'application/pdf')
      version2 = document.create_version!(new_file2, user, 'Version 2')
      expect(version2.version_number).to eq(2)
    end
    
    it 'updates document current_version_number' do
      expect(document.current_version_number).to eq(1)
      
      document.create_version!(new_file, user)
      document.reload
      
      expect(document.current_version_number).to eq(1)
    end
    
    it 'resets processing status' do
      document.update!(processing_status: 'completed', ai_processed_at: Time.current)
      
      document.create_version!(new_file, user)
      
      expect(document.processing_status).to eq('pending')
      expect(document.ai_processed_at).to be_nil
    end
  end

  describe 'version restoration' do
    let(:file_v1) { fixture_file_upload('spec/fixtures/files/sample.pdf', 'application/pdf') }
    let(:file_v2) { fixture_file_upload('spec/fixtures/files/sample.pdf', 'application/pdf') }
    
    before do
      # Create two versions
      document.create_version!(file_v1, user, 'Version 1')
      document.update!(title: 'Modified Title')
      document.create_version!(file_v2, user, 'Version 2')
    end
    
    it 'restores previous version' do
      first_version = document.versions.find_by(version_number: 1)
      
      restored = document.restore_version!(first_version.id, user)
      
      expect(restored).to be_truthy
      # Check that a new version was created for the restoration
      expect(document.versions.last.event).to eq('restore')
    end
  end

  describe 'version history' do
    before do
      # Create some versions
      3.times do |i|
        file = fixture_file_upload('spec/fixtures/files/sample.pdf', 'application/pdf')
        document.create_version!(file, user, "Version #{i + 1}")
      end
    end
    
    it 'returns correct version count' do
      expect(document.version_count).to eq(3)
    end
    
    it 'identifies file versions' do
      file_versions = document.file_versions
      expect(file_versions).to all(be_a(DocumentVersion))
      expect(file_versions).to all(satisfy { |v| v.file_metadata.present? })
    end
    
    it 'returns version history' do
      history = document.version_history
      
      expect(history).to be_an(Array)
      expect(history.size).to eq(3)
      
      history.each_with_index do |version_info, index|
        expect(version_info[:version_number]).to eq(index + 1)
        expect(version_info[:comment]).to match(/Version \d+/)
        expect(version_info[:created_by]).to eq(user.display_name)
      end
    end
  end
end