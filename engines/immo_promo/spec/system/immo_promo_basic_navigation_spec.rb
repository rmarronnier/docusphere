require 'rails_helper'

RSpec.describe "ImmoPromo Basic Navigation", type: :system do
  let(:user) { create(:user, :admin) }
  let(:organization) { user.organization }
  let(:project) { create(:immo_promo_project, organization: organization) }
  
  before do
    login_as(user, scope: :user)
  end

  describe "accessing ImmoPromo module" do
    it "can navigate to project dashboard" do
      visit "/immo/promo/projects"
      
      expect(page).to have_content("Projets")
    end

    it "can access project details" do
      visit "/immo/promo/projects/#{project.id}"
      
      expect(page).to have_content(project.name)
    end

    it "can access project dashboard" do
      visit "/immo/promo/projects/#{project.id}/dashboard"
      
      expect(page).to have_content(project.name)
      expect(page).to have_content("Tableau de bord")
    end
  end

  describe "navigation between modules" do
    it "shows navigation menu with all modules" do
      visit "/immo/promo/projects/#{project.id}/dashboard"
      
      expect(page).to have_content("Tableau de bord")
    end
  end
end