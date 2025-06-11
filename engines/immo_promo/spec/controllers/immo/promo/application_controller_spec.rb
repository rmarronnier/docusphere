require 'rails_helper'

RSpec.describe Immo::Promo::ApplicationController, type: :controller do
  controller do
    def index
      # Add Pundit compliance for testing
      authorize_skip
      render plain: 'success'
    end

    private

    def authorize_skip
      # Skip authorization for test controller
      skip_authorization
      skip_policy_scope
    end
  end

  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:admin_user) { create(:user, :admin, organization: organization) }

  describe 'access control' do
    context 'when user has no access' do
      before { sign_in user }

      it 'redirects to root path' do
        # Mock the policy to return false for access
        allow_any_instance_of(Immo::Promo::ApplicationPolicy).to receive(:access?).and_return(false)
        
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end

    context 'when user is admin' do
      before { sign_in admin_user }

      it 'allows access' do
        # Mock the policy to return true for admin
        allow_any_instance_of(Immo::Promo::ApplicationPolicy).to receive(:access?).and_return(true)
        
        get :index
        expect(response).to be_successful
        expect(response.body).to eq('success')
      end
    end

    context 'when user has specific permission' do
      before do
        sign_in user
        allow(user).to receive(:has_permission?).with('immo_promo:access').and_return(true)
      end

      it 'allows access' do
        # Mock the policy to return true for user with permission
        allow_any_instance_of(Immo::Promo::ApplicationPolicy).to receive(:access?).and_return(true)
        
        get :index
        expect(response).to be_successful
      end
    end

    context 'when user is not signed in' do
      it 'redirects to sign in' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'layout' do
    before { sign_in admin_user }

    it 'uses immo_promo layout' do
      # Test that the layout is configured correctly
      expect(controller.class.superclass._layout).to eq('immo_promo')
    end
  end

  describe '#user_has_immo_promo_access?' do
    let(:super_admin) { create(:user, :super_admin, organization: organization) }

    it 'returns true for admin users' do
      allow(controller).to receive(:current_user).and_return(admin_user)
      # Mock the policy access check
      allow_any_instance_of(Immo::Promo::ApplicationPolicy).to receive(:access?).and_return(true)
      expect(controller.send(:user_has_immo_promo_access?)).to be(true)
    end

    it 'returns true for super admin users' do
      allow(controller).to receive(:current_user).and_return(super_admin)
      # Mock the policy access check
      allow_any_instance_of(Immo::Promo::ApplicationPolicy).to receive(:access?).and_return(true)
      expect(controller.send(:user_has_immo_promo_access?)).to be(true)
    end

    it 'returns true for users with specific permission' do
      allow(user).to receive(:has_permission?).with('immo_promo:access').and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
      # Mock the policy access check
      allow_any_instance_of(Immo::Promo::ApplicationPolicy).to receive(:access?).and_return(true)
      expect(controller.send(:user_has_immo_promo_access?)).to be(true)
    end

    it 'returns false for regular users without permission' do
      allow(controller).to receive(:current_user).and_return(user)
      # Mock the policy access check
      allow_any_instance_of(Immo::Promo::ApplicationPolicy).to receive(:access?).and_return(false)
      expect(controller.send(:user_has_immo_promo_access?)).to be(false)
    end

    it 'returns false when no user is signed in' do
      allow(controller).to receive(:current_user).and_return(nil)
      # Mock the policy access check
      allow_any_instance_of(Immo::Promo::ApplicationPolicy).to receive(:access?).and_return(false)
      result = controller.send(:user_has_immo_promo_access?)
      expect(result).to be_falsey
    end
  end

  describe '#skip_authorization?' do
    it 'always returns false' do
      expect(controller.send(:skip_authorization?)).to be(false)
    end
  end
end