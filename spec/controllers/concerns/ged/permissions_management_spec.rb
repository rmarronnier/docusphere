require 'rails_helper'

RSpec.describe Ged::PermissionsManagement, type: :controller do
  controller(ApplicationController) do
    include Ged::PermissionsManagement
    
    def index
      render json: { status: 'ok' }
    end
  end

  let(:user) { create(:user) }
  let(:space) { create(:space, organization: user.organization) }
  let(:folder) { create(:folder, space: space) }
  let(:document) { create(:document, space: space, folder: folder, uploaded_by: user) }
  let(:other_user) { create(:user, organization: user.organization) }
  let(:user_group) { create(:user_group, organization: user.organization) }

  before do
    sign_in user
  end

  describe '#space_permissions' do
    it 'loads space and authorizations' do
      controller.params = { id: space.id }
      allow(controller).to receive(:policy_scope).and_return(Space.all)
      allow(controller).to receive(:authorize).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
      
      controller.space_permissions
      
      expect(controller.instance_variable_get(:@space)).to eq(space)
      expect(controller.instance_variable_get(:@authorizations)).to eq(space.authorizations)
      expect(controller.instance_variable_get(:@users)).to include(user, other_user)
      expect(controller.instance_variable_get(:@user_groups)).to include(user_group)
    end
  end

  describe '#update_space_permissions' do
    it 'updates authorizations successfully' do
      controller.params = { 
        id: space.id,
        permissions: {
          authorizations: [
            { user_id: other_user.id, permission_level: 'read' }
          ]
        }
      }
      allow(controller).to receive(:policy_scope).and_return(Space.all)
      allow(controller).to receive(:authorize).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:render)
      
      controller.update_space_permissions
      
      expect(space.authorizations.count).to eq(1)
      expect(space.authorizations.first.user).to eq(other_user)
      expect(space.authorizations.first.permission_level).to eq('read')
    end

    it 'removes authorizations with _destroy flag' do
      auth = create(:authorization, authorizable: space, user: other_user, permission_level: 'read')
      
      controller.params = { 
        id: space.id,
        permissions: {
          authorizations: [
            { user_id: other_user.id, _destroy: true }
          ]
        }
      }
      allow(controller).to receive(:policy_scope).and_return(Space.all)
      allow(controller).to receive(:authorize).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:render)
      
      controller.update_space_permissions
      
      expect(space.authorizations.count).to eq(0)
    end
  end

  describe '#folder_permissions' do
    it 'loads folder and authorizations' do
      controller.params = { id: folder.id }
      allow(controller).to receive(:policy_scope).and_return(Folder.all)
      allow(controller).to receive(:authorize).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
      
      controller.folder_permissions
      
      expect(controller.instance_variable_get(:@folder)).to eq(folder)
      expect(controller.instance_variable_get(:@authorizations)).to eq(folder.authorizations)
    end
  end

  describe '#document_permissions' do
    it 'loads document and authorizations' do
      controller.params = { id: document.id }
      allow(controller).to receive(:policy_scope).and_return(Document.all)
      allow(controller).to receive(:authorize).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
      
      controller.document_permissions
      
      expect(controller.instance_variable_get(:@document)).to eq(document)
      expect(controller.instance_variable_get(:@authorizations)).to eq(document.authorizations)
    end
  end
end