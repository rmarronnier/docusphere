require 'rails_helper'

RSpec.describe DocumentPolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:admin_user) { create(:user, :admin, organization: organization) }
  let(:super_admin_user) { create(:user, :super_admin, organization: organization) }
  let(:other_organization_user) { create(:user, organization: create(:organization)) }

  let(:space) { create(:space, organization: organization) }
  let(:other_organization_space) { create(:space, organization: other_organization_user.organization) }
  
  let(:document) { create(:document, uploaded_by: user, space: space) }
  let(:other_user_document) { create(:document, uploaded_by: other_organization_user, space: other_organization_space) }
  let(:same_org_document) { create(:document, uploaded_by: admin_user, space: space) }

  subject { described_class }

  permissions ".scope" do
    it "returns documents from user's organization" do
      other_document = create(:document, space: space)
      
      resolved_scope = subject::Scope.new(user, Document.all).resolve
      expect(resolved_scope).to include(document)
      expect(resolved_scope).to include(other_document)
      expect(resolved_scope).not_to include(other_user_document)
    end
  end

  permissions :show? do
    it "allows users to view documents in their organization" do
      expect(subject).to permit(user, document)
      expect(subject).to permit(user, same_org_document)
    end

    it "denies users viewing documents from other organizations" do
      expect(subject).not_to permit(user, other_user_document)
    end

    it "allows admins to view documents in their organization" do
      expect(subject).to permit(admin_user, document)
      expect(subject).to permit(admin_user, same_org_document)
    end

    it "allows super admins to view any document" do
      expect(subject).to permit(super_admin_user, document)
      expect(subject).to permit(super_admin_user, other_user_document)
    end
  end

  permissions :create? do
    it "allows authenticated users to create documents" do
      expect(subject).to permit(user, Document)
    end

    it "denies unauthenticated users" do
      expect(subject).not_to permit(nil, Document)
    end
  end

  permissions :update? do
    it "allows users to update their own documents" do
      expect(subject).to permit(user, document)
    end

    it "denies users updating others' documents" do
      expect(subject).not_to permit(user, same_org_document)
    end

    it "allows admins to update documents in their organization" do
      expect(subject).to permit(admin_user, document)
      expect(subject).to permit(admin_user, same_org_document)
    end

    it "denies admins updating documents from other organizations" do
      expect(subject).not_to permit(admin_user, other_user_document)
    end
  end

  permissions :destroy? do
    it "allows users to destroy their own documents" do
      expect(subject).to permit(user, document)
    end

    it "denies users destroying others' documents" do
      expect(subject).not_to permit(user, same_org_document)
    end

    it "allows admins to destroy any document" do
      expect(subject).to permit(admin_user, document)
      expect(subject).to permit(admin_user, same_org_document)
    end
  end

  permissions :download? do
    it "follows same rules as show" do
      expect(subject).to permit(user, document)
      expect(subject).to permit(user, same_org_document)
      expect(subject).not_to permit(user, other_user_document)
    end
  end

  permissions :preview? do
    it "follows same rules as show" do
      expect(subject).to permit(user, document)
      expect(subject).to permit(user, same_org_document)
      expect(subject).not_to permit(user, other_user_document)
    end
  end

  permissions :share? do
    it "allows document owners to share" do
      expect(subject).to permit(user, document)
    end

    it "denies non-owners from sharing" do
      expect(subject).not_to permit(user, same_org_document)
    end

    it "allows admins to share documents in their organization" do
      expect(subject).to permit(admin_user, document)
      expect(subject).to permit(admin_user, same_org_document)
    end
  end

  permissions :request_validation? do
    it "allows document owners to request validation" do
      expect(subject).to permit(user, document)
    end

    it "denies non-owners from requesting validation" do
      expect(subject).not_to permit(user, same_org_document)
    end
  end

  context "with documentable" do
    let(:documentable) { double("documentable") }
    let(:document_with_documentable) { create(:document, uploaded_by: user, space: nil, documentable: documentable) }

    before do
      allow(documentable).to receive(:can_read_documents?).and_return(true)
      allow(documentable).to receive(:can_manage_documents?).and_return(true)
    end

    permissions :show? do
      it "allows access when documentable allows reading" do
        expect(subject).to permit(user, document_with_documentable)
      end

      it "denies access when documentable denies reading" do
        allow(documentable).to receive(:can_read_documents?).and_return(false)
        expect(subject).not_to permit(user, document_with_documentable)
      end
    end

    permissions :update? do
      it "allows update when documentable allows managing" do
        expect(subject).to permit(user, document_with_documentable)
      end

      it "denies update when documentable denies managing" do
        allow(documentable).to receive(:can_manage_documents?).and_return(false)
        expect(subject).not_to permit(other_organization_user, document_with_documentable)
      end
    end
  end

  describe "#permitted_attributes" do
    it "returns base attributes for regular users" do
      policy = described_class.new(user, document)
      expect(policy.permitted_attributes).to contain_exactly(
        :title, :description, :document_type, :status, :is_template,
        :external_id, :expires_at, :is_public, :document_category,
        :file, :space_id, :folder_id, :documentable_id, :documentable_type,
        metadata: {}
      )
    end

    it "returns extended attributes for admins" do
      policy = described_class.new(admin_user, document)
      expect(policy.permitted_attributes).to include(
        :title, :description, :document_type, :status, :is_template,
        :external_id, :expires_at, :is_public, :document_category,
        :file, :space_id, :folder_id, :documentable_id, :documentable_type,
        :processing_status, :virus_scan_status, :ai_category,
        :ai_confidence, metadata: {}, ai_entities: {}, processing_metadata: {}
      )
    end

    it "returns extended attributes for super admins" do
      policy = described_class.new(super_admin_user, document)
      expect(policy.permitted_attributes).to include(
        :processing_status, :virus_scan_status, :ai_category,
        :ai_confidence, ai_entities: {}, processing_metadata: {}
      )
    end
  end
end