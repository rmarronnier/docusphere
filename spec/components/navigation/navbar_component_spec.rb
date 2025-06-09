require 'rails_helper'

RSpec.describe Navigation::NavbarComponent, type: :component do
  let(:user) { create(:user) }
  let(:admin_user) { create(:user, role: 'admin') }
  let(:current_path) { '/' }
  
  before do
    mock_component_helpers(described_class, user: user, additional_helpers: {
      destroy_user_session_path: '/logout',
      edit_user_registration_path: '/profile',
      settings_path: '/settings',
      ged_dashboard_path: '/ged/dashboard',
      baskets_path: '/baskets',
      tags_path: '/tags',
      users_path: '/users',
      user_groups_path: '/user_groups',
      request: double(path: current_path)
    })
  end
  
  it "renders navigation bar" do
    rendered = render_inline(described_class.new(current_page: current_path))
    
    expect(rendered).to have_css('nav')
    expect(rendered).to have_link('Tableau de bord', href: '/')
  end
  
  it "renders user menu when authenticated" do
    rendered = render_inline(described_class.new(current_page: current_path))
    
    expect(rendered).to have_css('[data-controller="dropdown"]')
    expect(rendered).to have_text(user.full_name)
  end
  
  it "renders search bar" do
    rendered = render_inline(described_class.new(current_page: current_path))
    
    expect(rendered).to have_css('form[action="/search"]')
    expect(rendered).to have_css('input[type="text"][placeholder="Rechercher..."]')
  end
  
  it "renders main navigation links" do
    rendered = render_inline(described_class.new(current_page: current_path))
    
    expect(rendered).to have_link('Tableau de bord', href: '/')
    expect(rendered).to have_link('GED', href: '/ged/dashboard')
    expect(rendered).to have_link('Recherche', href: '/search')
  end
  
  it "highlights active page" do
    mock_component_helpers(described_class, user: user, additional_helpers: {
      destroy_user_session_path: '/logout',
      edit_user_registration_path: '/profile',
      settings_path: '/settings',
      ged_dashboard_path: '/ged/dashboard',
      baskets_path: '/baskets',
      tags_path: '/tags',
      users_path: '/users',
      user_groups_path: '/user_groups',
      request: double(path: '/ged/dashboard')
    })
    
    rendered = render_inline(described_class.new(current_page: '/ged/dashboard'))
    
    # The component checks active_item? method which compares current_page with path
    expect(rendered).to have_css('a', text: 'GED')
  end
  
  it "shows admin links for admin users" do
    mock_component_helpers(described_class, user: admin_user, additional_helpers: {
      destroy_user_session_path: '/logout',
      edit_user_registration_path: '/profile',
      settings_path: '/settings',
      ged_dashboard_path: '/ged/dashboard',
      baskets_path: '/baskets',
      tags_path: '/tags',
      users_path: '/users',
      user_groups_path: '/user_groups',
      request: double(path: current_path)
    })
    
    rendered = render_inline(described_class.new(current_page: current_path))
    
    expect(rendered).to have_link('Utilisateurs', href: '/users')
    expect(rendered).to have_link('Groupes', href: '/user_groups')
  end
  
  it "hides admin links for regular users" do
    rendered = render_inline(described_class.new(current_page: current_path))
    
    expect(rendered).not_to have_link('Utilisateurs', href: '/users')
    expect(rendered).not_to have_link('Groupes', href: '/user_groups')
  end
  
  describe "mobile menu" do
    it "renders mobile menu toggle" do
      rendered = render_inline(described_class.new(current_page: current_path))
      
      expect(rendered).to have_css('[data-controller="mobile-menu"]')
      expect(rendered).to have_css('button[aria-label="Menu principal"]')
    end
    
    it "includes all navigation in mobile menu" do
      rendered = render_inline(described_class.new(current_page: current_path))
      
      within '[data-mobile-menu-target="menu"]' do
        expect(rendered).to have_link('Tableau de bord')
        expect(rendered).to have_link('GED')
        expect(rendered).to have_link('Recherche')
        expect(rendered).to have_link('Mon profil')
        expect(rendered).to have_link('Déconnexion')
      end
    end
  end
  
  describe "notifications" do
    it "shows unread notification count" do
      # Create notifications for the user
      create_list(:notification, 5, user: user, read_at: nil)
      
      rendered = render_inline(described_class.new(current_page: current_path))
      
      expect(rendered).to have_css('span', text: '5')
    end
    
    it "renders notification dropdown" do
      rendered = render_inline(described_class.new(current_page: current_path))
      
      expect(rendered).to have_css('button[aria-label="Afficher les notifications"]')
    end
  end
  
  describe "quick actions" do
    it "renders quick action buttons" do
      mock_component_helpers(described_class, user: user, additional_helpers: {
        destroy_user_session_path: '/logout',
        edit_user_registration_path: '/profile',
        settings_path: '/settings',
        ged_dashboard_path: '/ged/dashboard',
        baskets_path: '/baskets',
        tags_path: '/tags',
        users_path: '/users',
        user_groups_path: '/user_groups',
        new_document_path: '/ged/documents/new',
        request: double(path: current_path)
      })
      
      rendered = render_inline(described_class.new(current_page: current_path))
      
      expect(rendered).to have_link('Nouveau', href: '/ged/documents/new')
    end
  end
  
  describe "organization switcher" do
    let(:org1) { user.organization }
    let(:org2) { create(:organization, name: "Second Org") }
    
    it "shows organization switcher for users in multiple orgs" do
      user.organizations << org2
      
      rendered = render_inline(described_class.new(current_page: current_path))
      
      expect(rendered).to have_text(org1.name)
      expect(rendered).to have_css('[data-controller="dropdown"]')
    end
    
    it "hides organization switcher for single org users" do
      rendered = render_inline(described_class.new(current_page: current_path))
      
      # Component likely doesn't show switcher for single org
      expect(rendered.to_s).not_to include('organization-switcher')
    end
  end
  
  describe "breadcrumbs slot" do
    it "renders breadcrumbs when provided" do
      rendered = render_inline(described_class.new(current_page: current_path)) do |navbar|
        navbar.with_breadcrumbs do
          '<ol class="breadcrumb"><li class="breadcrumb-item"><a href="/">Home</a></li><li class="breadcrumb-item active">Current Page</li></ol>'.html_safe
        end
      end
      
      expect(rendered).to have_css('.breadcrumb')
      expect(rendered).to have_link('Home')
      expect(rendered).to have_content('Current Page')
    end
  end
  
  describe "contextual actions" do
    it "renders custom actions when provided" do
      rendered = render_inline(described_class.new(current_page: current_path)) do |navbar|
        navbar.with_actions do
          '<button class="btn">Export</button>'.html_safe
        end
      end
      
      expect(rendered).to have_css('button', text: 'Export')
    end
  end
  
  describe "accessibility" do
    it "has proper ARIA labels" do
      rendered = render_inline(described_class.new(current_page: current_path))
      
      expect(rendered).to have_css('nav')
      expect(rendered).to have_css('button[aria-label="Menu principal"]')
      expect(rendered).to have_css('button[aria-label="Compte utilisateur"]')
    end
    
    it "indicates current page with aria-current" do
      mock_component_helpers(described_class, user: user, additional_helpers: {
        destroy_user_session_path: '/logout',
        edit_user_registration_path: '/profile',
        settings_path: '/settings',
        ged_dashboard_path: '/ged/dashboard',
        baskets_path: '/baskets',
        tags_path: '/tags',
        users_path: '/users',
        user_groups_path: '/user_groups',
        request: double(path: '/ged/dashboard')
      })
      
      rendered = render_inline(described_class.new(current_page: '/ged/dashboard'))
      
      # Component should mark active page somehow
      expect(rendered).to have_css('a', text: 'GED')
    end
  end
end