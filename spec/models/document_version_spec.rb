require 'rails_helper'

RSpec.describe DocumentVersion, type: :model do
  let(:user) { create(:user) }
  let(:document) { create(:document, uploaded_by: user) }
  let(:version) { document.versions.last }

  describe 'inheritance' do
    it 'inherits from PaperTrail::Version' do
      expect(DocumentVersion.superclass).to eq(PaperTrail::Version)
    end
  end

  describe 'associations' do
    it 'belongs to a document as item' do
      expect(version.item).to eq(document)
      expect(version.item_type).to eq('Document')
    end
  end

  describe 'version creation' do
    it 'creates version on document creation' do
      new_doc = build(:document)
      expect { new_doc.save! }.to change { DocumentVersion.count }.by(1)
      
      version = DocumentVersion.last
      expect(version.event).to eq('create')
      expect(version.item).to eq(new_doc)
    end

    it 'creates version on document update' do
      expect {
        document.update!(title: 'Updated Title')
      }.to change { DocumentVersion.count }.by(1)
      
      version = DocumentVersion.last
      expect(version.event).to eq('update')
      expect(version.changeset['title']).to eq([document.title_was, 'Updated Title'])
    end
  end

  describe '#user' do
    it 'returns the user who made the change' do
      PaperTrail.request.whodunnit = user.id
      document.update!(title: 'Changed by user')
      
      version = DocumentVersion.last
      expect(version.user).to eq(user)
    end

    it 'returns nil when whodunnit is not set' do
      PaperTrail.request.whodunnit = nil
      document.update!(title: 'Anonymous change')
      
      version = DocumentVersion.last
      expect(version.user).to be_nil
    end
  end

  describe '#summary' do
    it 'returns summary of create event' do
      version = document.versions.find_by(event: 'create')
      expect(version.summary).to eq("Document créé")
    end

    it 'returns summary of update event with changed fields' do
      document.update!(title: 'New Title', description: 'New Description')
      version = DocumentVersion.last
      
      expect(version.summary).to include('Modifié:')
      expect(version.summary).to include('title')
      expect(version.summary).to include('description')
    end

    it 'returns summary of destroy event' do
      document.destroy
      version = DocumentVersion.last
      
      expect(version.event).to eq('destroy')
      expect(version.summary).to eq("Document supprimé")
    end
  end

  describe '#major_change?' do
    it 'identifies major changes' do
      document.update!(status: 'published')
      version = DocumentVersion.last
      expect(version.major_change?).to be true
    end

    it 'identifies file changes as major' do
      # Simulate file change
      document.update!(file_name: 'new_file.pdf', file_size: 2048)
      version = DocumentVersion.last
      expect(version.major_change?).to be true
    end

    it 'identifies minor changes' do
      document.update!(description: 'Minor update')
      version = DocumentVersion.last
      expect(version.major_change?).to be false
    end
  end

  describe '#changed_attributes' do
    it 'returns list of changed attribute names' do
      document.update!(
        title: 'New Title',
        description: 'New Description',
        status: 'published'
      )
      
      version = DocumentVersion.last
      expect(version.changed_attributes).to contain_exactly('title', 'description', 'status')
    end

    it 'returns empty array for create event' do
      version = document.versions.find_by(event: 'create')
      expect(version.changed_attributes).to eq([])
    end
  end

  describe '#file_change?' do
    it 'detects file-related changes' do
      document.update!(file_name: 'updated.pdf', file_size: 1024)
      version = DocumentVersion.last
      expect(version.file_change?).to be true
    end

    it 'returns false for non-file changes' do
      document.update!(title: 'New Title')
      version = DocumentVersion.last
      expect(version.file_change?).to be false
    end
  end

  describe '#metadata_change?' do
    it 'detects metadata changes' do
      document.update!(metadata: { author: 'John Doe' })
      version = DocumentVersion.last
      expect(version.metadata_change?).to be true
    end

    it 'returns false for non-metadata changes' do
      document.update!(title: 'New Title')
      version = DocumentVersion.last
      expect(version.metadata_change?).to be false
    end
  end

  describe 'scopes' do
    let!(:create_version) { document.versions.find_by(event: 'create') }
    let!(:update_version) do
      document.update!(title: 'Updated')
      DocumentVersion.last
    end
    let!(:major_version) do
      document.update!(status: 'published')
      DocumentVersion.last
    end

    describe '.creates' do
      it 'returns only create events' do
        expect(DocumentVersion.creates).to include(create_version)
        expect(DocumentVersion.creates).not_to include(update_version, major_version)
      end
    end

    describe '.updates' do
      it 'returns only update events' do
        expect(DocumentVersion.updates).to include(update_version, major_version)
        expect(DocumentVersion.updates).not_to include(create_version)
      end
    end

    describe '.major_changes' do
      it 'returns only major changes' do
        expect(DocumentVersion.major_changes).to include(major_version)
        expect(DocumentVersion.major_changes).not_to include(update_version)
      end
    end

    describe '.by_user' do
      it 'returns versions created by specific user' do
        PaperTrail.request.whodunnit = user.id
        document.update!(title: 'By specific user')
        user_version = DocumentVersion.last
        
        other_user = create(:user)
        PaperTrail.request.whodunnit = other_user.id
        document.update!(title: 'By other user')
        
        expect(DocumentVersion.by_user(user)).to include(user_version)
        expect(DocumentVersion.by_user(user).count).to eq(1)
      end
    end
  end

  describe '#restore!' do
    it 'restores document to this version state' do
      original_title = document.title
      original_description = document.description
      
      document.update!(title: 'V2', description: 'V2 Desc')
      v2_version = DocumentVersion.last
      
      document.update!(title: 'V3', description: 'V3 Desc')
      
      # Restore to V2
      v2_version.restore!
      document.reload
      
      expect(document.title).to eq('V2')
      expect(document.description).to eq('V2 Desc')
    end
  end

  describe 'version comparison' do
    let!(:v1) { document.versions.find_by(event: 'create') }
    let!(:v2) do
      document.update!(title: 'Version 2')
      DocumentVersion.last
    end
    let!(:v3) do
      document.update!(title: 'Version 3', status: 'published')
      DocumentVersion.last
    end

    describe '#differences_from' do
      it 'shows differences between versions' do
        diff = v3.differences_from(v1)
        expect(diff).to include('title', 'status')
      end
    end

    describe '#version_number' do
      it 'returns sequential version numbers' do
        expect(v1.version_number).to eq(1)
        expect(v2.version_number).to eq(2)
        expect(v3.version_number).to eq(3)
      end
    end
  end
end