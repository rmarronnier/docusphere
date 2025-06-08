require 'rails_helper'

RSpec.describe Navigation::NavbarComponent, type: :component do
  let(:user) { create(:user) }
  
  before do
    # Simuler l'authentification
    allow_any_instance_of(described_class).to receive(:current_user).and_return(user)
    # Pour les helpers de policy
    without_partial_double_verification do
      allow_any_instance_of(described_class).to receive(:helpers).and_return(
        double(
          current_user: user,
          policy: double(index?: true, create?: true)
        )
      )
    end
  end
  
  it "renders navigation bar" do
    render_inline(described_class.new)
    
    expect(page).to have_css('nav.navbar')
    expect(page).to have_link('Docusphere', href: '/')
  end
  
  it "renders user menu when authenticated" do
    render_inline(described_class.new)
    
    expect(page).to have_css('.user-menu')
    expect(page).to have_content(user.full_name)
    expect(page).to have_css('[data-controller="dropdown"]')
  end
  
  it "renders search bar" do
    render_inline(described_class.new)
    
    expect(page).to have_css('form.navbar-search')
    expect(page).to have_css('input[type="search"]')
    expect(page).to have_css('[data-controller="search-autocomplete"]')
  end
  
  it "renders main navigation links" do
    render_inline(described_class.new)
    
    expect(page).to have_link('Documents')
    expect(page).to have_link('Espaces')
    expect(page).to have_link('Tableau de bord')
  end
  
  it "highlights active page" do
    allow_any_instance_of(described_class).to receive(:current_page?).with('/documents').and_return(true)
    
    render_inline(described_class.new)
    
    expect(page).to have_css('.nav-link.active', text: 'Documents')
  end
  
  it "shows admin links for admin users" do
    user.update!(role: 'admin')
    
    render_inline(described_class.new)
    
    expect(page).to have_link('Administration')
    expect(page).to have_link('Utilisateurs')
    expect(page).to have_link('Paramètres')
  end
  
  it "hides admin links for regular users" do
    user.update!(role: 'user')
    
    render_inline(described_class.new)
    
    expect(page).not_to have_link('Administration')
  end
  
  describe "mobile menu" do
    it "renders mobile menu toggle" do
      render_inline(described_class.new)
      
      expect(page).to have_css('.mobile-menu-toggle')
      expect(page).to have_css('[data-action="click->mobile-menu#toggle"]')
    end
    
    it "includes all navigation in mobile menu" do
      render_inline(described_class.new)
      
      within '.mobile-menu' do
        expect(page).to have_link('Documents')
        expect(page).to have_link('Espaces')
        expect(page).to have_link('Mon profil')
        expect(page).to have_link('Déconnexion')
      end
    end
  end
  
  describe "notifications" do
    before do
      create_list(:notification, 3, user: user, read_at: nil)
      create_list(:notification, 2, user: user, read_at: 1.hour.ago)
    end
    
    it "shows unread notification count" do
      render_inline(described_class.new)
      
      expect(page).to have_css('.notification-badge', text: '3')
    end
    
    it "renders notification dropdown" do
      render_inline(described_class.new)
      
      expect(page).to have_css('[data-controller="notifications"]')
      expect(page).to have_css('.notification-dropdown')
    end
  end
  
  describe "quick actions" do
    it "renders quick action buttons" do
      render_inline(described_class.new)
      
      expect(page).to have_button('Nouveau document')
      expect(page).to have_css('[data-action="click->modal#open"]')
    end
  end
  
  describe "organization switcher" do
    let(:org1) { user.organization }
    let(:org2) { create(:organization, name: "Second Org") }
    
    before do
      user.organizations << org2
    end
    
    it "shows organization switcher for users in multiple orgs" do
      render_inline(described_class.new)
      
      expect(page).to have_css('.organization-switcher')
      expect(page).to have_content(org1.name)
      expect(page).to have_css('.dropdown-menu')
    end
    
    it "hides organization switcher for single org users" do
      user.organizations = [org1]
      
      render_inline(described_class.new)
      
      expect(page).not_to have_css('.organization-switcher')
    end
  end
  
  describe "breadcrumbs slot" do
    it "renders breadcrumbs when provided" do
      render_inline(described_class.new) do |navbar|
        navbar.with_breadcrumbs do
          content_tag :ol, class: "breadcrumb" do
            concat content_tag(:li, link_to("Home", "/"), class: "breadcrumb-item")
            concat content_tag(:li, "Current Page", class: "breadcrumb-item active")
          end
        end
      end
      
      expect(page).to have_css('.navbar-breadcrumbs')
      expect(page).to have_css('.breadcrumb')
      expect(page).to have_link('Home')
      expect(page).to have_content('Current Page')
    end
  end
  
  describe "contextual actions" do
    it "renders custom actions when provided" do
      render_inline(described_class.new) do |navbar|
        navbar.with_actions do
          render Ui::ButtonComponent.new(text: "Export", variant: :secondary, size: :sm)
          render Ui::ButtonComponent.new(text: "Filter", variant: :secondary, size: :sm)
        end
      end
      
      expect(page).to have_css('.navbar-actions')
      expect(page).to have_button('Export')
      expect(page).to have_button('Filter')
    end
  end
  
  describe "accessibility" do
    it "has proper ARIA labels" do
      render_inline(described_class.new)
      
      expect(page).to have_css('nav[role="navigation"]')
      expect(page).to have_css('[aria-label="Navigation principale"]')
      expect(page).to have_css('button[aria-label="Menu utilisateur"]')
      expect(page).to have_css('input[aria-label="Rechercher"]')
    end
    
    it "indicates current page with aria-current" do
      allow_any_instance_of(described_class).to receive(:current_page?).with('/documents').and_return(true)
      
      render_inline(described_class.new)
      
      expect(page).to have_css('[aria-current="page"]', text: 'Documents')
    end
  end
end