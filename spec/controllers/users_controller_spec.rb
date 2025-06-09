require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  let(:organization) { create(:organization) }
  let(:admin_user) { create(:user, :admin, organization: organization) }
  let(:regular_user) { create(:user, organization: organization, role: 'user') }
  let(:other_user) { create(:user, organization: organization) }
  
  before do
    sign_in admin_user
  end

  describe 'GET #index' do
    it 'returns a success response' do
      get :index
      expect(response).to be_successful
    end

    it 'assigns organization users' do
      regular_user
      get :index
      expect(assigns(:users)).to include(regular_user)
      expect(assigns(:users)).to include(admin_user)
    end

    it 'only shows users from current organization' do
      other_org_user = create(:user, organization: create(:organization))
      
      get :index
      expect(assigns(:users)).not_to include(other_org_user)
    end

    context 'with search parameter' do
      let!(:searched_user) { create(:user, organization: organization, first_name: 'John', last_name: 'Doe') }
      let!(:other_user) { create(:user, organization: organization, first_name: 'Jane', last_name: 'Smith') }

      it 'filters users by name' do
        get :index, params: { search: 'John' }
        expect(assigns(:users)).to include(searched_user)
        expect(assigns(:users)).not_to include(other_user)
      end

      it 'filters users by email' do
        get :index, params: { search: searched_user.email }
        expect(assigns(:users)).to include(searched_user)
        expect(assigns(:users)).not_to include(other_user)
      end
    end

  end

  describe 'GET #show' do
    it 'returns a success response' do
      get :show, params: { id: regular_user.id }
      expect(response).to be_successful
    end

    it 'assigns the requested user' do
      get :show, params: { id: regular_user.id }
      expect(assigns(:user)).to eq(regular_user)
    end


    it 'allows access to users from other organizations for admin' do
      other_org_user = create(:user, organization: create(:organization))
      
      get :show, params: { id: other_org_user.id }
      expect(response).to be_successful
      expect(assigns(:user)).to eq(other_org_user)
    end
  end

  describe 'GET #new' do
    it 'returns a success response' do
      get :new
      expect(response).to be_successful
    end

    it 'assigns a new user' do
      get :new
      expect(assigns(:user)).to be_a_new(User)
    end

    it 'assigns the user to current organization' do
      get :new
      expect(assigns(:user).organization).to eq(organization)
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      let(:valid_attributes) do
        {
          first_name: 'John',
          last_name: 'Doe',
          email: 'john@example.com',
          password: 'password123',
          password_confirmation: 'password123',
          role: 'user'
        }
      end

      it 'creates a new User' do
        expect {
          post :create, params: { user: valid_attributes }
        }.to change(User, :count).by(1)
      end

      it 'assigns the user to current organization' do
        post :create, params: { user: valid_attributes }
        expect(assigns(:user).organization).to eq(organization)
      end

      it 'redirects to the created user' do
        post :create, params: { user: valid_attributes }
        expect(response).to redirect_to(user_path(User.last))
      end

    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { { first_name: '', email: 'invalid-email' } }

      it 'does not create a new User' do
        expect {
          post :create, params: { user: invalid_attributes }
        }.to change(User, :count).by(0)
      end

      it 'renders new template' do
        post :create, params: { user: invalid_attributes }
        expect(response).to render_template(:new)
      end
    end

    context 'with duplicate email' do
      before { create(:user, email: 'duplicate@example.com') }

      it 'does not create user with duplicate email' do
        expect {
          post :create, params: { user: { email: 'duplicate@example.com', first_name: 'Test' } }
        }.to change(User, :count).by(0)
      end
    end
  end

  describe 'GET #edit' do
    it 'returns a success response' do
      get :edit, params: { id: regular_user.id }
      expect(response).to be_successful
    end

    it 'assigns the requested user' do
      get :edit, params: { id: regular_user.id }
      expect(assigns(:user)).to eq(regular_user)
    end
  end

  describe 'PATCH #update' do
    context 'with valid parameters' do
      let(:new_attributes) { { first_name: 'Updated', last_name: 'Name' } }

      it 'updates the requested user' do
        patch :update, params: { id: regular_user.id, user: new_attributes }
        regular_user.reload
        expect(regular_user.first_name).to eq('Updated')
        expect(regular_user.last_name).to eq('Name')
      end

      it 'redirects to the user' do
        patch :update, params: { id: regular_user.id, user: new_attributes }
        expect(response).to redirect_to(user_path(regular_user))
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { { email: 'invalid-email' } }

      it 'does not update the user' do
        original_email = regular_user.email
        patch :update, params: { id: regular_user.id, user: invalid_attributes }
        regular_user.reload
        expect(regular_user.email).to eq(original_email)
      end

      it 'renders edit template' do
        patch :update, params: { id: regular_user.id, user: invalid_attributes }
        expect(response).to render_template(:edit)
      end
    end

    context 'updating admin status' do
      it 'allows admin to promote user' do
        patch :update, params: { id: regular_user.id, user: { role: 'admin' } }
        regular_user.reload
        expect(regular_user.role).to eq('admin')
      end

      it 'allows admin to demote user' do
        admin = create(:user, :admin, organization: organization)
        patch :update, params: { id: admin.id, user: { role: 'user' } }
        admin.reload
        expect(admin.role).to eq('user')
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the user' do
      user_id = regular_user.id
      delete :destroy, params: { id: user_id }
      expect(User.exists?(user_id)).to be false
    end

    it 'redirects to the users list' do
      delete :destroy, params: { id: regular_user.id }
      expect(response).to redirect_to(users_path)
    end

    it 'prevents self-deletion' do
      delete :destroy, params: { id: admin_user.id }
      expect(response).to redirect_to(root_path)
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

      it 'redirects to root for viewing own profile' do
        get :show, params: { id: regular_user.id }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end

      it 'redirects to root for viewing other users' do
        get :show, params: { id: other_user.id }
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
      get :show, params: { id: regular_user.id }
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end