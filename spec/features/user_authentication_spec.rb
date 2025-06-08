require 'rails_helper'

RSpec.feature "User Authentication", type: :feature do
  let(:user) { create(:user, password: 'password123') }
  
  scenario "User signs in successfully" do
    visit new_user_session_path
    
    # Vérifier qu'on est sur la page de connexion
    expect(page).to have_content("Connexion")
    
    # Remplir le formulaire
    within "#new_user" do
      fill_in "Email", with: user.email
      fill_in "Mot de passe", with: "password123"
      check "Se souvenir de moi"
    end
    
    # Cliquer sur le bouton
    click_button "Se connecter"
    
    # Vérifier la redirection et le message
    expect(page).to have_current_path(root_path)
    expect(page).to have_content("Connecté avec succès")
    expect(page).to have_content(user.email)
    
    # Vérifier qu'on peut voir le lien de déconnexion
    expect(page).to have_link("Déconnexion")
    expect(page).not_to have_link("Connexion")
  end
  
  scenario "User fails to sign in with wrong password" do
    visit new_user_session_path
    
    within "#new_user" do
      fill_in "Email", with: user.email
      fill_in "Mot de passe", with: "wrongpassword"
    end
    
    click_button "Se connecter"
    
    # Rester sur la page de connexion
    expect(page).to have_current_path(new_user_session_path)
    expect(page).to have_content("Email ou mot de passe incorrect")
    
    # Le formulaire doit conserver l'email
    expect(find_field("Email").value).to eq(user.email)
  end
  
  scenario "User signs out" do
    # Se connecter d'abord
    login_as(user, scope: :user)
    
    visit root_path
    
    # Cliquer sur le menu utilisateur
    find('[data-action="click->dropdown#toggle"]').click
    
    # Cliquer sur déconnexion
    within '[data-dropdown-target="menu"]' do
      click_link "Déconnexion"
    end
    
    # Vérifier la déconnexion
    expect(page).to have_current_path(new_user_session_path)
    expect(page).to have_content("Déconnecté avec succès")
    expect(page).to have_link("Connexion")
    expect(page).not_to have_content(user.email)
  end
  
  scenario "User resets password" do
    visit new_user_session_path
    
    click_link "Mot de passe oublié?"
    
    expect(page).to have_current_path(new_user_password_path)
    
    fill_in "Email", with: user.email
    click_button "Envoyer les instructions"
    
    expect(page).to have_content("Vous allez recevoir un email")
    
    # Vérifier que l'email a été envoyé
    expect(ActionMailer::Base.deliveries.last.to).to include(user.email)
  end
end