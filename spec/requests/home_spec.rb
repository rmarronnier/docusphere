require 'rails_helper'

RSpec.describe "Homes", type: :request do
  let(:user) { create(:user) }
  
  before do
    sign_in user
  end
  
  describe "GET /index" do
    it "returns http success" do
      get root_path, headers: { 'Host' => 'localhost' }
      expect(response).to have_http_status(:success)
    end
    
    it "renders the index template" do
      get root_path, headers: { 'Host' => 'localhost' }
      expect(response).to render_template(:index)
    end
  end

end
