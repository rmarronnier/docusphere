require 'rails_helper'

RSpec.describe "Critical Path Tests", type: :integration do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:admin) { create(:user, role: 'admin', organization: organization) }
  let(:space) { create(:space, organization: organization) }
  
  before do
    # Use memory store for testing cache behavior
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
    Rails.cache.clear
  end
  
  describe "Document Management" do
    it "allows document upload, processing, and access control" do
      # Upload document
      document = create(:document, 
        space: space, 
        uploaded_by: user,
        title: "Test Document"
      )
      
      # Document should be owned by uploader
      expect(document.owned_by?(user)).to be true
      expect(document.owned_by?(admin)).to be false
      
      # Process document
      document.update!(processing_status: 'processing', processing_started_at: Time.current)
      expect(document.processing_status).to eq('processing')
      
      # Complete processing
      document.update!(processing_status: 'completed', processing_completed_at: Time.current)
      expect(document.processing_status).to eq('completed')
      
      # Grant permission to admin
      document.authorize_user(admin, 'read', granted_by: user)
      expect(document.readable_by?(admin)).to be true
      expect(document.writable_by?(admin)).to be false
    end
    
    it "handles document locking correctly" do
      document = create(:document, space: space, uploaded_by: user)
      
      # Lock document
      expect(document.lock_document!(user, reason: "Editing")).to be true
      expect(document.locked?).to be true
      expect(document.locked_by).to eq(user)
      
      # Other user cannot lock
      other_user = create(:user, organization: organization)
      expect(document.lock_document!(other_user)).to be false
      
      # Unlock
      expect(document.unlock_document!(user)).to be true
      expect(document.locked?).to be false
    end
  end
  
  describe "Validation Workflow" do
    it "handles document validation with polymorphic associations" do
      document = create(:document, space: space, uploaded_by: user)
      validator = create(:user, organization: organization)
      
      # Create validation request
      validation_request = ValidationRequest.create!(
        validatable: document,
        requester: user,
        min_validations: 1
      )
      
      # Add validator
      validation = DocumentValidation.create!(
        validation_request: validation_request,
        validatable: document,
        validator: validator,
        status: 'pending'
      )
      
      # Validate
      validation.update!(status: 'approved', validated_at: Time.current)
      validation_request.update!(status: 'completed', completed_at: Time.current)
      
      expect(document.validation_requests.count).to eq(1)
      expect(document.document_validations.count).to eq(1)
    end
  end
  
  describe "Permission System" do
    it "handles permissions correctly" do
      document = create(:document, space: space, uploaded_by: user)
      other_user = create(:user, organization: organization)
      
      # User without permission cannot read
      expect(document.readable_by?(other_user)).to be false
      
      # Grant permission
      auth = document.authorize_user(other_user, 'read', granted_by: user)
      expect(auth).to be_persisted
      
      # Now user can read
      expect(document.authorizations.active.for_user(other_user).exists?).to be true
      
      # Revoke permission
      auth.revoke!(user)
      
      # User can no longer read
      expect(document.authorizations.active.for_user(other_user).exists?).to be false
    end
  end
  
  describe "Folder Hierarchy" do
    it "manages folder hierarchy with cached paths" do
      root_folder = create(:folder, space: space, name: "Root")
      child_folder = create(:folder, space: space, parent: root_folder, name: "Child")
      grandchild_folder = create(:folder, space: space, parent: child_folder, name: "Grandchild")
      
      # Check hierarchy
      expect(grandchild_folder.ancestors).to eq([root_folder, child_folder])
      expect(grandchild_folder.root).to eq(root_folder)
      expect(grandchild_folder.depth).to eq(2)
      
      # Move grandchild to root
      grandchild_folder.update!(parent: root_folder)
      
      # Path should be updated
      expect(grandchild_folder.ancestors).to eq([root_folder])
      expect(grandchild_folder.depth).to eq(1)
    end
  end
  
  describe "Ownership Configuration" do
    it "respects configured ownership attributes" do
      # Document uses uploaded_by
      document = create(:document, space: space, uploaded_by: user)
      expect(document.owner).to eq(user)
      expect(document.owners).to eq([user])
      
      # Space has no ownership
      space = create(:space, organization: organization)
      expect(space.owner).to be_nil
      expect(space.owners).to be_empty
      expect(space.owned_by?(user)).to be false
    end
  end
  
  describe "User Groups" do
    it "handles group permissions correctly" do
      document = create(:document, space: space, uploaded_by: user)
      group = create(:user_group, organization: organization)
      member1 = create(:user, organization: organization)
      member2 = create(:user, organization: organization)
      
      # Add members to group
      group.add_user(member1)
      group.add_user(member2)
      
      # Grant permission to group
      document.authorize_group(group, 'write', granted_by: user)
      
      # All members should have access
      expect(document.writable_by?(member1)).to be true
      expect(document.writable_by?(member2)).to be true
      
      # Remove member from group
      group.remove_user(member1)
      group.reload
      
      # Verify member is removed
      expect(group.users).not_to include(member1)
      expect(group.users).to include(member2)
    end
  end
end