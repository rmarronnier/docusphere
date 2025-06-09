require 'rails_helper'

RSpec.describe 'User Management', type: :system do
  let(:organization) { create(:organization) }
  let(:admin) { create(:user, :admin, organization: organization) }
  let(:regular_user) { create(:user, organization: organization) }
  
  before do
    driven_by(:selenium_chrome_headless)
  end
  
  describe 'Admin access' do
    before do
      login_as(admin, scope: :user)
    end
    
    it 'displays users in the navigation' do
      visit root_path
      
      expect(page).to have_link('Utilisateurs')
      expect(page).to have_link('Groupes')
    end
    
    it 'allows viewing all users' do
      user1 = create(:user, organization: organization, first_name: 'Alice', last_name: 'Smith')
      user2 = create(:user, organization: organization, first_name: 'Bob', last_name: 'Jones')
      
      visit users_path
      
      expect(page).to have_content('Utilisateurs')
      expect(page).to have_content('Alice Smith')
      expect(page).to have_content('Bob Jones')
      expect(page).to have_content(user1.email)
      expect(page).to have_content(user2.email)
    end
    
    it 'allows searching users' do
      create(:user, organization: organization, first_name: 'Alice', last_name: 'Smith')
      create(:user, organization: organization, first_name: 'Bob', last_name: 'Jones')
      
      visit users_path
      
      fill_in 'search', with: 'Alice'
      click_button 'Rechercher'
      
      expect(page).to have_content('Alice Smith')
      expect(page).not_to have_content('Bob Jones')
    end
    
    it 'allows creating a new user' do
      visit users_path
      click_link 'Nouvel utilisateur'
      
      fill_in 'Prénom', with: 'John'
      fill_in 'Nom', with: 'Doe'
      fill_in 'Email', with: 'john.doe@example.com'
      select 'Manager', from: 'Rôle'
      fill_in 'Mot de passe', with: 'password123'
      fill_in 'Confirmer le mot de passe', with: 'password123'
      
      click_button 'Créer l\'utilisateur'
      
      expect(page).to have_content('Utilisateur créé avec succès')
      expect(page).to have_content('John Doe')
      expect(page).to have_content('john.doe@example.com')
      expect(page).to have_content('Manager')
    end
    
    it 'validates user creation' do
      visit new_user_path
      
      click_button 'Créer l\'utilisateur'
      
      expect(page).to have_content('empêchent l\'enregistrement')
      expect(page).to have_content('First name doit être rempli(e)')
      expect(page).to have_content('Last name doit être rempli(e)')
      expect(page).to have_content('Email doit être rempli(e)')
    end
    
    it 'allows editing a user' do
      user = create(:user, organization: organization, first_name: 'John', last_name: 'Doe')
      
      visit user_path(user)
      click_link 'Modifier'
      
      fill_in 'Prénom', with: 'Jane'
      fill_in 'Nom', with: 'Smith'
      select 'Administrateur', from: 'Rôle'
      
      click_button 'Enregistrer'
      
      expect(page).to have_content('Utilisateur mis à jour avec succès')
      expect(page).to have_content('Jane Smith')
      expect(page).to have_content('Administrateur')
    end
    
    it 'allows deleting a user' do
      user = create(:user, organization: organization, first_name: 'John', last_name: 'Doe')
      
      visit user_path(user)
      
      accept_confirm do
        click_link 'Supprimer'
      end
      
      expect(page).to have_content('Utilisateur supprimé avec succès')
      expect(page).to have_current_path(users_path)
      expect(page).not_to have_content('John Doe')
    end
    
    it 'prevents deleting own account' do
      visit user_path(admin)
      
      accept_confirm do
        click_link 'Supprimer'
      end
      
      expect(page).to have_content('Vous ne pouvez pas supprimer votre propre compte')
    end
  end
  
  describe 'Regular user access' do
    before do
      login_as(regular_user, scope: :user)
    end
    
    it 'does not show user management links in navigation' do
      visit root_path
      
      expect(page).not_to have_link('Utilisateurs', href: users_path)
      expect(page).not_to have_link('Groupes', href: user_groups_path)
    end
    
    it 'denies access to users index' do
      visit users_path
      
      expect(page).to have_content('Accès refusé')
      expect(page).to have_current_path(root_path)
    end
    
    it 'denies access to create user' do
      visit new_user_path
      
      expect(page).to have_content('Accès refusé')
      expect(page).to have_current_path(root_path)
    end
  end
  
  describe 'User groups management' do
    let!(:group) { create(:user_group, organization: organization, name: 'Developers') }
    
    before do
      login_as(admin, scope: :user)
    end
    
    it 'displays all groups' do
      create(:user_group, organization: organization, name: 'Managers')
      
      visit user_groups_path
      
      expect(page).to have_content('Groupes d\'utilisateurs')
      expect(page).to have_content('Developers')
      expect(page).to have_content('Managers')
    end
    
    it 'allows creating a new group' do
      visit user_groups_path
      click_link 'Nouveau groupe'
      
      fill_in 'Nom du groupe', with: 'Marketing Team'
      fill_in 'Description', with: 'Marketing department members'
      select 'Département', from: 'Type de groupe'
      check 'Groupe actif'
      
      click_button 'Créer le groupe'
      
      expect(page).to have_content('Groupe créé avec succès')
      expect(page).to have_content('Marketing Team')
      expect(page).to have_content('Marketing department members')
      expect(page).to have_content('Actif')
    end
    
    it 'allows adding members to a group' do
      user = create(:user, organization: organization, first_name: 'Alice', last_name: 'Smith')
      
      visit user_group_path(group)
      click_button 'Ajouter un membre'
      
      select 'Alice Smith', from: 'Utilisateur'
      select 'Membre', from: 'Rôle'
      
      click_button 'Ajouter'
      
      expect(page).to have_content('Membre ajouté avec succès')
      expect(page).to have_content('Alice Smith')
      expect(page).to have_content('Membre')
    end
    
    it 'allows removing members from a group' do
      user = create(:user, organization: organization, first_name: 'Bob', last_name: 'Jones')
      group.add_user(user)
      
      visit user_group_path(group)
      
      accept_confirm do
        click_link 'Retirer'
      end
      
      expect(page).to have_content('Membre retiré avec succès')
      expect(page).not_to have_content('Bob Jones')
    end
    
    it 'allows editing group permissions' do
      visit edit_user_group_path(group)
      
      check 'Document read'
      check 'Document write'
      check 'Immo promo access'
      
      click_button 'Enregistrer'
      
      expect(page).to have_content('Groupe mis à jour avec succès')
      
      # Verify permissions are saved
      visit user_group_path(group)
      expect(page).to have_content('document:read')
      expect(page).to have_content('document:write')
      expect(page).to have_content('immo_promo:access')
    end
  end
  
  describe 'User profile display' do
    before do
      login_as(admin, scope: :user)
    end
    
    it 'shows user details and groups' do
      user = create(:user, organization: organization, first_name: 'Alice', last_name: 'Smith')
      group1 = create(:user_group, organization: organization, name: 'Developers')
      group2 = create(:user_group, organization: organization, name: 'Managers')
      
      group1.add_user(user, role: 'member')
      group2.add_user(user, role: 'admin')
      
      visit user_path(user)
      
      expect(page).to have_content('Alice Smith')
      expect(page).to have_content(user.email)
      expect(page).to have_content(organization.name)
      
      # Check groups section
      expect(page).to have_content('Groupes d\'utilisateurs')
      expect(page).to have_content('Developers')
      expect(page).to have_content('Managers')
      expect(page).to have_content('Rôle : Member')
      expect(page).to have_content('Rôle : Admin')
    end
  end
end