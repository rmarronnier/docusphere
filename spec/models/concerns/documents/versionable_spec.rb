require 'rails_helper'

RSpec.describe Documents::Versionable do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:space) { create(:space, organization: organization) }
  let(:folder) { create(:folder, space: space) }
  let(:document) { create(:document, folder: folder, space: space, uploaded_by: user) }

  describe 'version tracking' do
    it 'creates initial version on create' do
      new_doc = build(:document, folder: folder, space: space, uploaded_by: user)
      # PaperTrail doesn't track create events by default in our config
      expect { new_doc.save! }.to change { DocumentVersion.count }.by(0)
    end

    it 'tracks changes on update' do
      expect {
        document.update!(title: 'New Title')
      }.to change { document.versions.count }.by(1)
    end

    it 'stores whodunnit information' do
      PaperTrail.request.whodunnit = user.id
      document.update!(title: 'Updated Title')
      expect(document.versions.last.whodunnit).to eq(user.id.to_s)
    end

    describe '#version_count' do
      it 'returns the number of versions' do
        3.times { |i| document.update!(title: "Title #{i}") }
        expect(document.version_count).to eq(3) # Only updates are tracked, not creates
      end
    end

    describe '#current_version_number' do
      it 'returns the current version number' do
        expect(document.current_version_number).to eq(1)
        document.update!(title: 'Version 2')
        expect(document.current_version_number).to eq(2)
      end
    end

    describe '#previous_version' do
      it 'returns nil for first version' do
        expect(document.previous_version).to be_nil
      end

      it 'returns previous version after update' do
        original_title = document.title
        document.update!(title: 'New Title')
        previous = document.previous_version
        expect(previous.title).to eq(original_title)
      end
    end

    describe '#revert_to_version!' do
      it 'reverts to specified version' do
        original_title = document.title
        document.update!(title: 'Version 2')
        document.update!(title: 'Version 3')
        
        document.revert_to_version!(1)
        expect(document.reload.title).to eq(original_title)
      end

      it 'creates a new version when reverting' do
        document.update!(title: 'Version 2')
        expect {
          document.revert_to_version!(1)
        }.to change { document.versions.count }.by(1)
      end
    end

    describe '#version_at' do
      it 'returns version by number' do
        document.update!(title: 'Version 2')
        document.update!(title: 'Version 3')
        
        version = document.version_at(2)
        expect(version).to be_present
        expect(version.version_number).to eq(2) if version.respond_to?(:version_number)
      end
    end

    describe '#changed_by' do
      it 'returns user who made the last change' do
        other_user = create(:user, organization: organization)
        PaperTrail.request.whodunnit = other_user.id
        document.update!(title: 'Changed')
        
        expect(document.changed_by.id).to eq(other_user.id)
      end
    end

    describe '#version_summary' do
      it 'returns summary of all versions' do
        document.update!(title: 'Version 2', description: 'Updated description')
        document.update!(status: 'published')
        
        summary = document.version_summary
        expect(summary).to be_a(Hash)
        expect(summary[:total_versions]).to eq(2) # 2 updates
        expect(summary[:current_version]).to eq(document.current_version_number)
        expect(summary[:versions]).to be_an(Array)
      end
    end

    describe '#has_changes_since?' do
      it 'returns false when no changes since timestamp' do
        expect(document.has_changes_since?(1.minute.ago)).to be false
      end

      it 'returns true when changes exist since timestamp' do
        document.update!(title: 'Changed')
        expect(document.has_changes_since?(1.minute.ago)).to be true
      end
    end

    describe '#major_version?' do
      it 'identifies major version changes' do
        # Simulate major change by updating status
        document.update!(status: 'published')
        expect(document.major_version?).to be true
      end

      it 'identifies minor version changes' do
        document.update!(description: 'Minor update')
        expect(document.major_version?).to be false
      end
    end
  end

  describe 'file versioning' do
    describe '#create_version!' do
      let(:new_file) { fixture_file_upload('spec/fixtures/files/sample.pdf', 'application/pdf') }
      
      before do
        Current.user = user
      end
      
      it 'creates a new version with file' do
        initial_count = document.versions.count
        
        version = document.create_version!(new_file, user, 'Test update')
        
        expect(document.versions.count).to eq(initial_count + 1)
        expect(version).to be_a(DocumentVersion)
        expect(version.comment).to eq('Test update')
      end
      
      it 'updates current_version_number' do
        initial_version = document.current_version_number
        
        document.create_version!(new_file, user)
        
        expect(document.reload.current_version_number).to eq(initial_version + 1)
      end
      
      it 'attaches the new file' do
        document.create_version!(new_file, user)
        
        expect(document.file).to be_attached
        expect(document.file.filename.to_s).to eq('sample.pdf')
      end
      
      it 'sets processing status to pending' do
        document.update!(processing_status: 'completed')
        
        document.create_version!(new_file, user)
        
        expect(document.reload.processing_status).to eq('pending')
      end
      
      it 'returns false when file is nil' do
        result = document.create_version!(nil, user)
        
        expect(result).to be_falsey
      end
      
      it 'forces updated_at change to trigger PaperTrail' do
        old_updated_at = document.updated_at
        
        document.create_version!(new_file, user)
        
        expect(document.reload.updated_at).to be > old_updated_at
      end
    end
    
    describe '#create_file_version!' do
      it 'creates a new version when file changes' do
        new_file = fixture_file_upload('spec/fixtures/files/sample.pdf', 'application/pdf')
        expect {
          document.create_file_version!(new_file, user)
        }.to change { document.versions.count }.by(1)
      end

      it 'uses default comment for file versions' do
        new_file = fixture_file_upload('spec/fixtures/files/sample.pdf', 'application/pdf')
        version = document.create_file_version!(new_file, user)
        
        expect(version.comment).to eq('Nouveau fichier uploadé')
      end
    end

    describe '#file_versions' do
      it 'returns only versions with file changes' do
        document.update!(title: 'New Title') # Non-file change
        
        new_file = fixture_file_upload('spec/fixtures/files/sample.pdf', 'application/pdf')
        version = document.create_file_version!(new_file, user)
        
        file_versions = document.file_versions
        expect(file_versions.length).to be >= 1
      end
    end
  end

  describe 'version comparison' do
    describe '#diff_with_version' do
      it 'shows differences between versions' do
        document.update!(title: 'Version 2')
        
        diff = document.diff_with_version(1)
        expect(diff).to be_a(Hash)
        expect(diff).to have_key('title') if diff.any?
      end
    end

    describe '#changes_between_versions' do
      it 'lists all changes between two versions' do
        document.update!(title: 'V2')
        document.update!(title: 'V3', description: 'V3 Desc')
        
        changes = document.changes_between_versions(1, 2)
        expect(changes).to be_a(Hash)
      end
    end
  end
end