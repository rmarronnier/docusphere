require 'rails_helper'

RSpec.feature "Organization Management", type: :feature do
  let(:admin_user) { create(:user, role: 'admin') }
  let(:organization) { admin_user.organization }
  
  before do
    login_as(admin_user, scope: :user)
  end
  
  scenario "Admin creates a new user" do
    visit organization_users_path
    
    click_link "Nouvel utilisateur"
    
    # Formulaire de création
    fill_in "Prénom", with: "Jean"
    fill_in "Nom", with: "Dupont"
    fill_in "Email", with: "jean.dupont@example.com"
    select "Utilisateur", from: "Rôle"
    
    # Permissions
    check "Accès aux documents"
    check "Création de documents"
    uncheck "Administration"
    
    click_button "Créer l'utilisateur"
    
    expect(page).to have_content("Utilisateur créé avec succès")
    expect(page).to have_content("jean.dupont@example.com")
    expect(page).to have_content("Un email d'invitation a été envoyé")
    
    # Vérifier dans la liste
    within ".users-table" do
      expect(page).to have_content("Jean Dupont")
      expect(page).to have_content("Utilisateur")
      expect(page).to have_content("En attente")
    end
  end
  
  scenario "Admin manages user groups" do
    visit organization_user_groups_path
    
    click_link "Nouveau groupe"
    
    # Créer un groupe
    fill_in "Nom du groupe", with: "Équipe Marketing"
    fill_in "Description", with: "Tous les membres du département marketing"
    
    click_button "Créer"
    
    expect(page).to have_content("Groupe créé avec succès")
    
    # Ajouter des membres
    click_link "Équipe Marketing"
    click_link "Gérer les membres"
    
    # Sélectionner des utilisateurs
    user1 = create(:user, organization: organization)
    user2 = create(:user, organization: organization)
    
    visit current_path # Recharger pour voir les nouveaux utilisateurs
    
    check "user_#{user1.id}"
    check "user_#{user2.id}"
    
    click_button "Ajouter les membres sélectionnés"
    
    expect(page).to have_content("2 membres ajoutés au groupe")
    
    within ".group-members" do
      expect(page).to have_content(user1.full_name)
      expect(page).to have_content(user2.full_name)
    end
  end
  
  scenario "Admin configures organization settings" do
    visit organization_settings_path
    
    # Informations générales
    within "#general-settings" do
      fill_in "Nom de l'organisation", with: "Ma Société SARL"
      fill_in "Adresse", with: "123 Rue de la Paix"
      fill_in "Code postal", with: "75001"
      fill_in "Ville", with: "Paris"
      
      click_button "Enregistrer"
    end
    
    expect(page).to have_content("Paramètres mis à jour")
    
    # Configuration de sécurité
    click_link "Sécurité"
    
    within "#security-settings" do
      check "Authentification à deux facteurs obligatoire"
      fill_in "Durée de session (minutes)", with: "60"
      check "Forcer le changement de mot de passe tous les 90 jours"
      
      click_button "Enregistrer"
    end
    
    expect(page).to have_content("Paramètres de sécurité mis à jour")
  end
  
  scenario "Admin views organization statistics" do
    # Créer des données de test
    5.times { create(:user, organization: organization) }
    10.times { create(:document, space: create(:space, organization: organization)) }
    
    visit organization_dashboard_path
    
    # Statistiques générales
    within ".organization-stats" do
      expect(page).to have_content("6 Utilisateurs") # 5 + admin
      expect(page).to have_content("10 Documents")
      expect(page).to have_content("Espace utilisé")
    end
    
    # Graphiques d'activité
    expect(page).to have_css(".activity-chart")
    expect(page).to have_content("Activité des 30 derniers jours")
    
    # Utilisateurs actifs
    within ".active-users" do
      expect(page).to have_content("Utilisateurs actifs")
      expect(page).to have_content(admin_user.full_name)
    end
  end
  
  scenario "Admin manages spaces" do
    visit organization_spaces_path
    
    click_link "Nouvel espace"
    
    # Créer un espace
    fill_in "Nom", with: "Espace RH"
    fill_in "Description", with: "Documents des ressources humaines"
    
    # Définir les permissions par défaut
    select "Lecture seule", from: "Permissions par défaut"
    
    # Sélectionner les groupes ayant accès
    group = create(:user_group, organization: organization, name: "RH")
    visit current_path # Recharger
    
    check "group_#{group.id}"
    
    click_button "Créer l'espace"
    
    expect(page).to have_content("Espace créé avec succès")
    expect(page).to have_content("Espace RH")
    
    # Configurer l'espace
    click_link "Espace RH"
    click_link "Configuration"
    
    # Quota
    fill_in "Quota (GB)", with: "50"
    check "Activer la corbeille"
    fill_in "Durée de rétention (jours)", with: "30"
    
    click_button "Enregistrer"
    
    expect(page).to have_content("Configuration mise à jour")
  end
  
  scenario "Admin manages metadata templates" do
    visit organization_metadata_templates_path
    
    click_link "Nouveau modèle"
    
    # Créer un modèle
    fill_in "Nom du modèle", with: "Facture"
    fill_in "Description", with: "Modèle pour les factures"
    
    # Ajouter des champs
    click_button "Ajouter un champ"
    
    within ".field-builder" do
      fill_in "Nom du champ", with: "numero_facture"
      fill_in "Label", with: "Numéro de facture"
      select "Texte", from: "Type"
      check "Obligatoire"
      
      click_button "Valider"
    end
    
    click_button "Ajouter un champ"
    
    within ".field-builder:last-child" do
      fill_in "Nom du champ", with: "montant"
      fill_in "Label", with: "Montant TTC"
      select "Nombre", from: "Type"
      check "Obligatoire"
      
      click_button "Valider"
    end
    
    click_button "Créer le modèle"
    
    expect(page).to have_content("Modèle créé avec succès")
    
    # Vérifier le modèle
    within ".templates-list" do
      expect(page).to have_content("Facture")
      expect(page).to have_content("2 champs")
    end
  end
  
  scenario "Admin configures workflows" do
    visit organization_workflows_path
    
    click_link "Nouveau workflow"
    
    # Créer un workflow
    fill_in "Nom", with: "Validation des contrats"
    fill_in "Description", with: "Processus de validation des contrats clients"
    
    # Ajouter des étapes
    click_button "Ajouter une étape"
    
    within ".step-form" do
      fill_in "Nom de l'étape", with: "Revue juridique"
      select "Équipe Juridique", from: "Assigné à"
      fill_in "Délai (jours)", with: "3"
      
      click_button "Valider"
    end
    
    click_button "Ajouter une étape"
    
    within ".step-form:last-child" do
      fill_in "Nom de l'étape", with: "Validation direction"
      select "Direction", from: "Assigné à"
      fill_in "Délai (jours)", with: "2"
      check "Étape finale"
      
      click_button "Valider"
    end
    
    click_button "Créer le workflow"
    
    expect(page).to have_content("Workflow créé avec succès")
    
    # Tester le workflow
    within ".workflows-list" do
      expect(page).to have_content("Validation des contrats")
      expect(page).to have_content("2 étapes")
      expect(page).to have_content("Actif")
    end
  end
  
  scenario "Admin exports organization data" do
    visit organization_settings_path
    
    click_link "Export des données"
    
    # Options d'export
    check "Utilisateurs"
    check "Documents"
    check "Métadonnées"
    check "Historique d'activité"
    
    select "JSON", from: "Format"
    
    # Options de confidentialité
    check "Anonymiser les données personnelles"
    uncheck "Inclure le contenu des documents"
    
    click_button "Générer l'export"
    
    expect(page).to have_content("Export en cours de génération")
    expect(page).to have_content("Vous recevrez un email lorsque l'export sera prêt")
    
    # Vérifier la liste des exports
    click_link "Exports précédents"
    
    within ".exports-list" do
      expect(page).to have_content("En cours")
      expect(page).to have_content("Export complet")
      expect(page).to have_content(admin_user.full_name)
    end
  end
  
  scenario "Admin manages organization billing" do
    visit organization_billing_path
    
    # Informations de facturation actuelles
    within ".current-plan" do
      expect(page).to have_content("Plan actuel")
      expect(page).to have_content("Professionnel")
      expect(page).to have_content("100 utilisateurs")
      expect(page).to have_content("1 TB de stockage")
    end
    
    # Historique de facturation
    within ".billing-history" do
      expect(page).to have_content("Historique de facturation")
      expect(page).to have_css("table")
    end
    
    # Changer de plan
    click_link "Changer de plan"
    
    within ".plan-options" do
      # Sélectionner un nouveau plan
      within "#enterprise-plan" do
        expect(page).to have_content("Enterprise")
        expect(page).to have_content("Utilisateurs illimités")
        expect(page).to have_content("5 TB de stockage")
        
        click_button "Sélectionner"
      end
    end
    
    # Confirmer le changement
    expect(page).to have_content("Confirmer le changement de plan")
    expect(page).to have_content("Nouveau plan: Enterprise")
    
    click_button "Confirmer"
    
    expect(page).to have_content("Plan mis à jour avec succès")
  end
end