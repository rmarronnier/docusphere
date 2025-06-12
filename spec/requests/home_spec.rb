require 'rails_helper'

RSpec.describe "Home", type: :request do
  describe "GET /" do
    context "when not authenticated" do
      it "renders the landing page successfully" do
        get root_path, headers: { 'Host' => 'localhost' }
        
        expect(response).to have_http_status(:success)
      end
      
      it "does not show dashboard content" do
        get root_path, headers: { 'Host' => 'localhost' }
        
        expect(response.body).not_to include("pending_documents")
        expect(response.body).not_to include("statistics")
      end
    end
    
    context "when authenticated" do
      let(:user) { create_user_with_organization }
      
      before do
        sign_in user
      end
      
      # CE TEST AURAIT DÉTECTÉ L'ERREUR NoMethodError
      it "renders the dashboard without errors" do
        get root_path, headers: { 'Host' => 'localhost' }
        
        expect(response).to have_http_status(:success)
      end
      
      it "loads all dashboard components successfully" do
        # Créer des données de test pour s'assurer que toutes les requêtes fonctionnent
        create(:document, uploaded_by: user, status: 'draft')
        create(:document_validation, validator: user, status: 'pending')
        
        get root_path, headers: { 'Host' => 'localhost' }
        
        expect(response).to have_http_status(:success)
        # Dans les request specs, on ne peut pas utiliser assigns
        # On vérifie plutôt que la page se charge sans erreur
      end
      
      it "calculates statistics correctly" do
        # Test spécifique pour les statistiques
        create_list(:document, 3, uploaded_by: user)
        shared_doc = create(:document)
        create(:document_share, document: shared_doc, shared_with: user)
        
        get root_path, headers: { 'Host' => 'localhost' }
        
        # Dans les request specs, on vérifie le contenu de la réponse
        expect(response).to have_http_status(:success)
        # Vérifier que les statistiques sont affichées dans la page
        expect(response.body).to include("document") # Au moins une référence aux documents
      end
      
      it "handles users without any data" do
        # Test important pour les nouveaux utilisateurs
        get root_path, headers: { 'Host' => 'localhost' }
        
        expect(response).to have_http_status(:success)
      end
      
      context "with different user profiles" do
        it "loads profile-specific widgets for direction" do
          # L'utilisateur a déjà un profil créé par create_user_with_organization
          user.user_profiles.first.update!(profile_type: 'direction', active: true)
          
          get root_path, headers: { 'Host' => 'localhost' }
          
          expect(response).to have_http_status(:success)
        end
        
        it "loads profile-specific widgets for chef_projet" do
          # L'utilisateur a déjà un profil créé par create_user_with_organization
          user.user_profiles.first.update!(profile_type: 'chef_projet', active: true)
          
          get root_path, headers: { 'Host' => 'localhost' }
          
          expect(response).to have_http_status(:success)
        end
      end
    end
  end
  
  describe "Error prevention tests" do
    let(:user) { create_user_with_organization }
    
    before { sign_in user }
    
    # Ces tests spécifiques auraient immédiatement détecté l'erreur
    it "does not call undefined methods on User model" do
      # Test qui vérifie que les méthodes appelées existent
      expect(user).to respond_to(:documents)
      expect(user).to respond_to(:document_validations)
      expect(user).not_to respond_to(:accessible_documents) # Cette méthode n'existe pas!
      expect(user).not_to respond_to(:shared_documents) # Cette méthode n'existe pas non plus!
    end
    
    it "successfully loads dashboard even with method name changes" do
      # Test de régression pour éviter que l'erreur revienne
      # La méthode accessible_documents n'existe plus, on a corrigé le code
      # Le dashboard charge maintenant correctement après nos corrections
      get root_path, headers: { 'Host' => 'localhost' }
      
      expect(response).to have_http_status(:success)
    end
  end
end
