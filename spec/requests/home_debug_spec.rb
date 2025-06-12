require 'rails_helper'

RSpec.describe "Home Debug", type: :request do
  describe "GET / debugging" do
    let(:organization) { create(:organization) }
    let(:user) { create(:user, organization: organization) }
    
    before do
      create(:user_profile, user: user, active: true)
    end
    
    it "debugs the authentication flow" do
      # Test sans authentification
      get root_path
      puts "Without auth - Status: #{response.status}"
      puts "Without auth - Redirected to: #{response.location}" if response.redirect?
      
      # Test avec authentification
      sign_in user
      get root_path
      puts "With auth - Status: #{response.status}"
      puts "With auth - Body snippet: #{response.body[0..200]}" if response.body
      puts "With auth - Headers: #{response.headers.select { |k,v| k =~ /location|content-type/i }}"
      
      # Si erreur, afficher plus de détails
      if response.status >= 400
        puts "Error response body: #{response.body}"
      end
      
      expect(response).to have_http_status(:success).or have_http_status(:redirect)
    end
    
    it "checks controller and action" do
      sign_in user
      
      # Ajouter des headers de debug
      get root_path, headers: { 'X-Debug': 'true' }
      
      puts "Controller: #{@controller&.class&.name}"
      puts "Action: #{@controller&.action_name}" if @controller
      puts "Params: #{@controller&.params&.to_unsafe_h}" if @controller
      
      expect(response).not_to have_http_status(:forbidden)
    end
  end
end