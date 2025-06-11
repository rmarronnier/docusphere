require 'rails_helper'

RSpec.describe Documents::Versionable do
  let(:user) { create(:user) }
  let(:document) { create(:document, uploaded_by: user) }

  describe 'version tracking' do
    it 'creates initial version on create' do
      new_doc = build(:document)
      expect { new_doc.save! }.to change { PaperTrail::Version.count }.by(1)
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
        expect(document.version_count).to eq(4) # 1 create + 3 updates
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
      it 'returns document state at specific time' do
        original_title = document.title
        
        travel 1.hour do
          document.update!(title: 'Hour Later')
        end
        
        version_at_start = document.version_at(30.minutes.ago)
        expect(version_at_start.title).to eq(original_title)
      end
    end

    describe '#changed_by' do
      it 'returns user who made the last change' do
        other_user = create(:user)
        PaperTrail.request.whodunnit = other_user.id
        document.update!(title: 'Changed')
        
        expect(document.changed_by).to eq(other_user)
      end
    end

    describe '#version_summary' do
      it 'returns summary of all versions' do
        document.update!(title: 'Version 2', description: 'Updated description')
        document.update!(status: 'published')
        
        summary = document.version_summary
        expect(summary).to be_an(Array)
        expect(summary.length).to eq(3) # create + 2 updates
        
        latest = summary.first
        expect(latest[:version]).to eq(3)
        expect(latest[:changes]).to include('status')
      end
    end

    describe '#has_changes_since?' do
      it 'returns false when no changes since timestamp' do
        expect(document.has_changes_since?(1.minute.ago)).to be false
      end

      it 'returns true when changes exist since timestamp' do
        travel 1.hour do
          document.update!(title: 'Changed')
        end
        expect(document.has_changes_since?(30.minutes.ago)).to be true
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
    describe '#create_file_version!' do
      it 'creates a new version when file changes' do
        new_file = fixture_file_upload('spec/fixtures/test_document.pdf', 'application/pdf')
        expect {
          document.file.attach(new_file)
          document.create_file_version!
        }.to change { document.versions.count }.by(1)
      end

      it 'stores file metadata in version' do
        document.create_file_version!
        version = document.versions.last
        expect(version.object_changes).to include('file_version')
      end
    end

    describe '#file_versions' do
      it 'returns only versions with file changes' do
        document.update!(title: 'New Title') # Non-file change
        
        new_file = fixture_file_upload('spec/fixtures/test_document.pdf', 'application/pdf')
        document.file.attach(new_file)
        document.create_file_version!
        
        file_versions = document.file_versions
        expect(file_versions.length).to eq(1)
      end
    end
  end

  describe 'version comparison' do
    describe '#diff_with_version' do
      it 'shows differences between versions' do
        original_attrs = document.attributes
        document.update!(
          title: 'New Title',
          description: 'New Description'
        )
        
        diff = document.diff_with_version(1)
        expect(diff['title']).to eq([original_attrs['title'], 'New Title'])
        expect(diff['description']).to eq([original_attrs['description'], 'New Description'])
      end
    end

    describe '#changes_between_versions' do
      it 'lists all changes between two versions' do
        document.update!(title: 'V2')
        document.update!(title: 'V3', description: 'V3 Desc')
        document.update!(status: 'published')
        
        changes = document.changes_between_versions(2, 4)
        expect(changes).to include('title', 'description', 'status')
      end
    end
  end
end