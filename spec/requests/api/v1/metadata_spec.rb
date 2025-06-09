require 'rails_helper'

# TODO: API V1 NOT YET IMPLEMENTED
# These tests are for a future API implementation.
# The API will require:
# - Authentication mechanism (token-based or JWT)
# - API controllers in app/controllers/api/v1/
# - Metadata management endpoints
# - Proper JSON serialization for metadata templates
#
# IMPORTANT: Uncomment and update these tests when implementing the API

RSpec.describe "API V1 Metadata", type: :request do
  pending "API V1 not yet implemented - waiting for API authentication system"
  
  # let(:user) { create(:user, role: 'admin') }
  # let(:organization) { user.organization }
  # 
  # # Note: Current implementation uses Devise sign_in
  # # API will need token-based authentication instead
  # let(:valid_headers) {
  #   {
  #     "Content-Type" => "application/json",
  #     "Accept" => "application/json"
  #   }
  # }
  # 
  # before do
  #   sign_in user  # This won't work for API - need token auth
  # end
  # 
  # describe "GET /api/v1/metadata/templates" do
  #   let!(:templates) {
  #     [
  #       create(:metadata_template, 
  #         name: "Contract Metadata",
  #         organization: organization
  #       ),
  #       create(:metadata_template,
  #         name: "Invoice Metadata", 
  #         organization: organization
  #       )
  #     ]
  #   }
  #   
  #   it "returns metadata templates" do
  #     get "/api/v1/metadata/templates", headers: valid_headers
  #     
  #     expect(response).to have_http_status(:ok)
  #     json = JSON.parse(response.body)
  #     expect(json['data'].size).to eq(2)
  #   end
  # end
end