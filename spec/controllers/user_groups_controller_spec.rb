require 'rails_helper'

RSpec.describe UserGroupsController, type: :controller do
  let(:organization) { create(:organization) }
  let(:admin_user) { create(:user, :admin, organization: organization) }
  let(:regular_user) { create(:user, organization: organization, role: 'user') }
  let(:user_group) { create(:user_group, organization: organization) }
  
  before do
    sign_in admin_user
  end

  describe 'GET #index' do
    it 'returns a success response' do
      get :index
      expect(response).to be_successful
    end

    it 'assigns organization user groups' do
      user_group
      get :index
      expect(assigns(:user_groups)).to include(user_group)
    end

    it 'only shows groups from current organization' do
      other_org_group = create(:user_group, organization: create(:organization))
      
      get :index
      expect(assigns(:user_groups)).not_to include(other_org_group)
    end

    context 'with search parameter' do
      let!(:searched_group) { create(:user_group, organization: organization, name: 'Administrators') }
      let!(:other_group) { create(:user_group, organization: organization, name: 'Users') }

      it 'filters groups by name' do
        get :index, params: { search: 'Admin' }
        expect(assigns(:user_groups)).to include(searched_group)
        expect(assigns(:user_groups)).not_to include(other_group)
      end
    end
  end

  describe 'GET #show' do
    it 'returns a success response' do
      get :show, params: { id: user_group.id }
      expect(response).to be_successful
    end

    it 'assigns the requested user group' do
      get :show, params: { id: user_group.id }
      expect(assigns(:user_group)).to eq(user_group)
    end

    it 'assigns group members' do
      membership = create(:user_group_membership, user_group: user_group, user: regular_user)
      
      get :show, params: { id: user_group.id }
      expect(assigns(:members)).to include(membership)
    end

    it 'allows access to groups from other organizations for admin' do
      other_org_group = create(:user_group, organization: create(:organization))
      
      get :show, params: { id: other_org_group.id }
      expect(response).to be_successful
      expect(assigns(:user_group)).to eq(other_org_group)
    end
  end

  describe 'GET #new' do
    it 'returns a success response' do
      get :new
      expect(response).to be_successful
    end

    it 'assigns a new user group' do
      get :new
      expect(assigns(:user_group)).to be_a_new(UserGroup)
    end

    it 'assigns the group to current organization' do
      get :new
      expect(assigns(:user_group).organization).to eq(organization)
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      let(:valid_attributes) do
        {
          name: 'Test Group',
          description: 'A test user group',
          active: true
        }
      end

      it 'creates a new UserGroup' do
        expect {
          post :create, params: { user_group: valid_attributes }
        }.to change(UserGroup, :count).by(1)
      end

      it 'assigns the group to current organization' do
        post :create, params: { user_group: valid_attributes }
        expect(assigns(:user_group).organization).to eq(organization)
      end

      it 'redirects to the created user group' do
        post :create, params: { user_group: valid_attributes }
        expect(response).to redirect_to(user_group_path(UserGroup.last))
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { { name: '', description: 'Test Description' } }

      it 'does not create a new UserGroup' do
        expect {
          post :create, params: { user_group: invalid_attributes }
        }.to change(UserGroup, :count).by(0)
      end

      it 'renders new template' do
        post :create, params: { user_group: invalid_attributes }
        expect(response).to render_template(:new)
      end
    end

    context 'with duplicate name in organization' do
      before { create(:user_group, name: 'Duplicate', organization: organization) }

      it 'does not create group with duplicate name' do
        expect {
          post :create, params: { user_group: { name: 'Duplicate', description: 'Test' } }
        }.to change(UserGroup, :count).by(0)
      end
    end
  end

  describe 'GET #edit' do
    it 'returns a success response' do
      get :edit, params: { id: user_group.id }
      expect(response).to be_successful
    end

    it 'assigns the requested user group' do
      get :edit, params: { id: user_group.id }
      expect(assigns(:user_group)).to eq(user_group)
    end
  end

  describe 'PATCH #update' do
    context 'with valid parameters' do
      let(:new_attributes) { { name: 'Updated Group Name', description: 'Updated description' } }

      it 'updates the requested user group' do
        patch :update, params: { id: user_group.id, user_group: new_attributes }
        user_group.reload
        expect(user_group.name).to eq('Updated Group Name')
        expect(user_group.description).to eq('Updated description')
      end

      it 'redirects to the user group' do
        patch :update, params: { id: user_group.id, user_group: new_attributes }
        expect(response).to redirect_to(user_group_path(user_group))
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { { name: '' } }

      it 'does not update the user group' do
        original_name = user_group.name
        patch :update, params: { id: user_group.id, user_group: invalid_attributes }
        user_group.reload
        expect(user_group.name).to eq(original_name)
      end

      it 'renders edit template' do
        patch :update, params: { id: user_group.id, user_group: invalid_attributes }
        expect(response).to render_template(:edit)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested user group' do
      user_group
      expect {
        delete :destroy, params: { id: user_group.id }
      }.to change(UserGroup, :count).by(-1)
    end

    it 'redirects to the user groups list' do
      delete :destroy, params: { id: user_group.id }
      expect(response).to redirect_to(user_groups_path)
    end

    context 'group with members' do
      before do
        create(:user_group_membership, user_group: user_group, user: regular_user)
      end

      it 'removes all memberships when destroyed' do
        expect {
          delete :destroy, params: { id: user_group.id }
        }.to change(UserGroupMembership, :count).by(-1)
      end
    end

    context 'group with authorizations' do
      let(:space) { create(:space, organization: organization) }
      
      before do
        create(:authorization, :for_group,
               authorizable: space,
               user_group: user_group,
               permission_level: 'read',
               granted_by: admin_user)
      end

      it 'removes all authorizations when destroyed' do
        expect {
          delete :destroy, params: { id: user_group.id }
        }.to change(Authorization, :count).by(-1)
      end
    end
  end

  describe 'POST #add_member' do
    it 'adds user to group' do
      expect {
        post :add_member, params: { id: user_group.id, user_id: regular_user.id }
      }.to change(user_group.users, :count).by(1)
    end

    it 'redirects to group show page' do
      post :add_member, params: { id: user_group.id, user_id: regular_user.id }
      expect(response).to redirect_to(user_group_path(user_group))
    end


    it 'prevents adding user twice' do
      create(:user_group_membership, user_group: user_group, user: regular_user)
      
      expect {
        post :add_member, params: { id: user_group.id, user_id: regular_user.id }
      }.to change(user_group.users, :count).by(0)
    end

    it 'prevents adding users from other organizations' do
      other_org_user = create(:user, organization: create(:organization))
      
      post :add_member, params: { id: user_group.id, user_id: other_org_user.id }
      expect(response).to redirect_to(user_group_path(user_group))
      expect(flash[:alert]).to match(/appartient pas à la même organisation/)
    end
  end

  describe 'DELETE #remove_member' do
    let!(:membership) { create(:user_group_membership, user_group: user_group, user: regular_user) }

    it 'removes user from group' do
      expect {
        delete :remove_member, params: { id: user_group.id, user_id: regular_user.id }
      }.to change(user_group.users, :count).by(-1)
    end

    it 'redirects to group show page' do
      delete :remove_member, params: { id: user_group.id, user_id: regular_user.id }
      expect(response).to redirect_to(user_group_path(user_group))
    end

  end


  describe 'authorization' do
    context 'when signed in as regular user' do
      before { sign_in regular_user }

      it 'redirects to root for index' do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end

      it 'redirects to root for new' do
        get :new
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end

      it 'redirects to root for show' do
        get :show, params: { id: user_group.id }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe 'authentication' do
    before { sign_out admin_user }

    it 'redirects to login for index' do
      get :index
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects to login for show' do
      get :show, params: { id: user_group.id }
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end