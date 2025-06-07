require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  controller do
    def index
      render plain: 'test'
    end
  end

  describe 'Devise parameter configuration' do
    let(:organization) { create(:organization) }
    
    before do
      @request.env["devise.mapping"] = Devise.mappings[:user]
    end

    describe '#configure_permitted_parameters' do
      it 'permits additional parameters for sign up' do
        allow(controller).to receive(:devise_controller?).and_return(true)
        
        # Create parameters with the expected fields
        params = ActionController::Parameters.new(user: {
          email: 'test@example.com',
          password: 'password',
          first_name: 'Test',
          last_name: 'User',
          organization_id: organization.id
        })
        
        controller.instance_variable_set(:@devise_parameter_sanitizer, Devise::ParameterSanitizer.new(User, :user, params))
        
        controller.send(:configure_permitted_parameters)
        
        permitted_params = controller.devise_parameter_sanitizer.sanitize(:sign_up)
        expect(permitted_params.keys).to include('email', 'password', 'first_name', 'last_name', 'organization_id')
      end
    end
  end

  describe 'CSRF protection' do
    it 'protects from forgery attacks' do
      expect(controller.class.forgery_protection_strategy).to eq(ActionController::RequestForgeryProtection::ProtectionMethods::Exception)
    end
  end
end