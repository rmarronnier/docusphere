require 'rails_helper'

RSpec.describe "Document Sharing Workflow", type: :system do
  let(:owner) { create(:user) }
  let(:recipient) { create(:user) }
  let(:external_email) { "external@example.com" }
  let(:space) { create(:space, organization: owner.organization) }
  let(:document) { create(:document, 
    title: "Rapport Confidentiel",
    space: space,
    user: owner,
    processing_status: 'completed'
  )}
  
  before do
    login_as(owner, scope: :user)
    document # Ensure document exists
  end
  
  describe "internal sharing", js: true do
    it "shares document with another user in organization" do
      # Créer un utilisateur dans la même organisation
      colleague = create(:user, organization: owner.organization)
      
      visit ged_document_path(document)
      
      # Ouvrir le menu de partage
      click_button "Partager"
      
      expect(page).to have_css('#shareModal:not(.hidden)', wait: 2)
      
      within '#shareModal' do
        # Chercher l'utilisateur
        fill_in "search_users", with: colleague.email
        
        # Attendre les résultats de recherche
        expect(page).to have_css('.user-search-results', wait: 2)
        
        within '.user-search-results' do
          click_on colleague.full_name
        end
        
        # L'utilisateur doit apparaître dans la liste
        within '.selected-users' do
          expect(page).to have_content(colleague.full_name)
          
          # Définir les permissions
          select "Lecture seule", from: "permission_#{colleague.id}"
        end
        
        # Ajouter un message
        fill_in "share_message", with: "Voici le rapport dont nous avons discuté"
        
        # Définir une date d'expiration
        fill_in "expires_at", with: 7.days.from_now.strftime("%Y-%m-%d")
        
        click_button "Partager"
      end
      
      expect(page).to have_content("Document partagé avec succès")
      
      # Vérifier que le partage apparaît
      within '.document-shares' do
        expect(page).to have_content(colleague.full_name)
        expect(page).to have_content("Lecture seule")
        expect(page).to have_content("Expire dans 7 jours")
      end
      
      # Se connecter en tant que destinataire
      logout(:user)
      login_as(colleague, scope: :user)
      
      # Vérifier la notification
      visit root_path
      within '.notifications' do
        expect(page).to have_content("Nouveau document partagé")
      end
      
      # Accéder au document partagé
      visit ged_dashboard_path
      click_link "Documents partagés avec moi"
      
      expect(page).to have_content("Rapport Confidentiel")
      click_link "Rapport Confidentiel"
      
      # Vérifier les permissions limitées
      expect(page).to have_button("Télécharger")
      expect(page).not_to have_button("Modifier")
      expect(page).not_to have_button("Supprimer")
    end
    
    it "shares with user group" do
      group = create(:user_group, organization: owner.organization, name: "Équipe Finance")
      user1 = create(:user, organization: owner.organization)
      user2 = create(:user, organization: owner.organization)
      group.add_user(user1, role: 'member')
      group.add_user(user2, role: 'member')
      
      visit ged_document_path(document)
      click_button "Partager"
      
      within '#shareModal' do
        # Basculer vers l'onglet groupes
        click_link "Groupes"
        
        # Sélectionner le groupe
        within '.groups-list' do
          check "group_#{group.id}"
        end
        
        # Définir les permissions pour le groupe
        select "Lecture et écriture", from: "group_permission_#{group.id}"
        
        click_button "Partager"
      end
      
      expect(page).to have_content("Document partagé avec 1 groupe")
      
      # Vérifier que tous les membres du groupe ont accès
      logout(:user)
      login_as(user1, scope: :user)
      
      visit ged_document_path(document)
      expect(page).to have_content("Rapport Confidentiel")
      expect(page).to have_button("Modifier")
    end
  end
  
  describe "external sharing", js: true do
    it "creates shareable link with password protection" do
      visit ged_document_path(document)
      click_button "Partager"
      
      within '#shareModal' do
        # Basculer vers l'onglet lien
        click_link "Créer un lien"
        
        # Activer la protection par mot de passe
        check "require_password"
        fill_in "link_password", with: "SecurePass123!"
        
        # Définir les restrictions
        check "allow_download"
        uncheck "allow_print"
        fill_in "max_downloads", with: "5"
        fill_in "link_expires_at", with: 3.days.from_now.strftime("%Y-%m-%d")
        
        click_button "Créer le lien"
      end
      
      # Le lien doit être affiché
      within '.share-link-container' do
        expect(page).to have_content("Lien créé avec succès")
        expect(page).to have_css('input.share-link-input')
        
        # Copier le lien
        click_button "Copier"
        expect(page).to have_content("Lien copié")
      end
      
      # Tester le lien en mode incognito (non connecté)
      share_link = find('.share-link-input').value
      logout(:user)
      
      visit share_link
      
      # Doit demander le mot de passe
      expect(page).to have_content("Ce document est protégé par mot de passe")
      fill_in "password", with: "SecurePass123!"
      click_button "Accéder"
      
      # Doit voir le document avec restrictions
      expect(page).to have_content("Rapport Confidentiel")
      expect(page).to have_button("Télécharger")
      expect(page).not_to have_button("Imprimer")
      
      # Vérifier le compteur de téléchargements
      click_button "Télécharger"
      expect(page).to have_content("4 téléchargements restants")
    end
    
    it "sends document by email" do
      visit ged_document_path(document)
      click_button "Partager"
      
      within '#shareModal' do
        click_link "Envoyer par email"
        
        # Ajouter des destinataires
        fill_in "email_recipients", with: "john@example.com, jane@example.com"
        
        # Personnaliser le message
        fill_in "email_subject", with: "Document important à consulter"
        fill_in "email_message", with: "Bonjour,\n\nMerci de consulter ce document important.\n\nCordialement"
        
        # Options d'envoi
        choose "send_as_link" # vs send_as_attachment
        check "request_read_receipt"
        
        click_button "Envoyer"
      end
      
      expect(page).to have_content("Email envoyé à 2 destinataires")
      
      # Vérifier l'historique des partages
      within '.sharing-history' do
        expect(page).to have_content("Envoyé par email à john@example.com")
        expect(page).to have_content("Envoyé par email à jane@example.com")
      end
    end
  end
  
  describe "share management", js: true do
    let!(:share) { create(:document_share, 
      document: document,
      shared_by: owner,
      shared_with: recipient,
      permission: 'read'
    )}
    
    it "modifies existing share permissions" do
      visit ged_document_path(document)
      
      within '.document-shares' do
        expect(page).to have_content(recipient.full_name)
        
        # Ouvrir le menu d'actions
        within "#share_#{share.id}" do
          find('[data-action="click->dropdown#toggle"]').click
          
          within '[data-dropdown-target="menu"]' do
            click_link "Modifier les permissions"
          end
        end
      end
      
      within '#editShareModal' do
        select "Lecture et écriture", from: "permission"
        check "allow_reshare"
        
        click_button "Enregistrer"
      end
      
      expect(page).to have_content("Permissions mises à jour")
      
      within '.document-shares' do
        expect(page).to have_content("Lecture et écriture")
        expect(page).to have_content("Peut repartager")
      end
    end
    
    it "revokes document share" do
      visit ged_document_path(document)
      
      within '.document-shares' do
        within "#share_#{share.id}" do
          find('[data-action="click->dropdown#toggle"]').click
          
          within '[data-dropdown-target="menu"]' do
            click_link "Révoquer l'accès"
          end
        end
      end
      
      # Confirmer la révocation
      page.accept_confirm
      
      expect(page).to have_content("Accès révoqué")
      expect(page).not_to have_content(recipient.full_name)
      
      # Vérifier que le destinataire n'a plus accès
      logout(:user)
      login_as(recipient, scope: :user)
      
      visit ged_document_path(document)
      expect(page).to have_content("Vous n'avez pas accès à ce document")
    end
    
    it "tracks share access and downloads" do
      # Simuler plusieurs accès
      logout(:user)
      login_as(recipient, scope: :user)
      
      # Premier accès
      visit ged_document_path(document)
      expect(page).to have_content("Rapport Confidentiel")
      
      # Télécharger
      click_button "Télécharger"
      
      # Deuxième accès
      visit ged_document_path(document)
      
      # Revenir au propriétaire pour voir les stats
      logout(:user)
      login_as(owner, scope: :user)
      
      visit ged_document_path(document)
      
      within '.document-shares' do
        within "#share_#{share.id}" do
          expect(page).to have_content("Consulté 2 fois")
          expect(page).to have_content("Téléchargé 1 fois")
          expect(page).to have_content("Dernier accès il y a moins d'une minute")
        end
      end
    end
  end
  
  describe "bulk sharing", js: true do
    let!(:doc2) { create(:document, title: "Document 2", space: space, user: owner) }
    let!(:doc3) { create(:document, title: "Document 3", space: space, user: owner) }
    
    it "shares multiple documents at once" do
      visit ged_space_path(space)
      
      # Activer la sélection multiple
      click_button "Sélection multiple"
      
      # Sélectionner plusieurs documents
      check "select_document_#{document.id}"
      check "select_document_#{doc2.id}"
      check "select_document_#{doc3.id}"
      
      within '.bulk-actions-bar' do
        click_button "Partager"
      end
      
      within '#bulkShareModal' do
        # Ajouter un destinataire
        fill_in "search_users", with: recipient.email
        
        within '.user-search-results' do
          click_on recipient.full_name
        end
        
        # Permissions communes
        select "Lecture seule", from: "bulk_permission"
        
        # Message
        fill_in "bulk_share_message", with: "Voici les 3 documents demandés"
        
        click_button "Partager les documents"
      end
      
      expect(page).to have_content("3 documents partagés avec succès")
      
      # Vérifier que le destinataire voit tous les documents
      logout(:user)
      login_as(recipient, scope: :user)
      
      visit ged_dashboard_path
      click_link "Documents partagés avec moi"
      
      expect(page).to have_content("Rapport Confidentiel")
      expect(page).to have_content("Document 2")
      expect(page).to have_content("Document 3")
      expect(page).to have_content("3 documents")
    end
  end
  
  describe "share templates", js: true do
    it "saves and reuses sharing configurations" do
      visit ged_document_path(document)
      click_button "Partager"
      
      within '#shareModal' do
        # Configurer le partage
        fill_in "search_users", with: recipient.email
        within '.user-search-results' do
          click_on recipient.full_name
        end
        
        select "Lecture seule", from: "permission_#{recipient.id}"
        fill_in "expires_at", with: 30.days.from_now.strftime("%Y-%m-%d")
        
        # Sauvegarder comme modèle
        check "save_as_template"
        fill_in "template_name", with: "Partage standard 30 jours"
        
        click_button "Partager"
      end
      
      # Utiliser le modèle sur un autre document
      visit ged_document_path(doc2)
      click_button "Partager"
      
      within '#shareModal' do
        # Charger le modèle
        select "Partage standard 30 jours", from: "share_template"
        
        # Les paramètres doivent être pré-remplis
        within '.selected-users' do
          expect(page).to have_content(recipient.full_name)
        end
        expect(find_field("expires_at").value).to eq(30.days.from_now.strftime("%Y-%m-%d"))
        
        click_button "Partager"
      end
      
      expect(page).to have_content("Document partagé avec succès")
    end
  end
end