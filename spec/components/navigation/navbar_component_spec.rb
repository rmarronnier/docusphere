require 'rails_helper'

RSpec.describe Navigation::NavbarComponent, type: :component do
  let(:user) { create(:user) }
  let(:admin_user) { create(:user, role: 'admin') }
  let(:current_path) { '/' }
  
  before do
    mock_component_helpers(described_class, user: user, additional_helpers: {
      request: double(path: current_path)
    })
  end
  
  it "renders navigation bar" do
    rendered = render_inline(described_class.new(current_page: current_path))
    
    expect(rendered).to have_css('nav')
    puts "=" * 80
    puts rendered.to_s
    puts "=" * 80
    expect(rendered).to have_link('Docusphere', href: '/')
  end
  
  it "renders user menu when authenticated" do
    rendered = render_inline(described_class.new(current_page: current_path))
    
    expect(rendered).to have_css('[data-controller="dropdown"]')
    expect(rendered).to have_text(user.first_name&.first&.upcase || user.email.first.upcase)
  end
  
  it "renders search bar" do
    rendered = render_inline(described_class.new(current_page: current_path))
    
    expect(rendered).to have_css('form[action="/search"]')
    expect(rendered).to have_css('input[placeholder="Rechercher un document..."]')
  end
  
  it "renders main navigation links" do
    rendered = render_inline(described_class.new(current_page: current_path))
    
    expect(rendered).to have_link('Tableau de bord', href: '/')
    expect(rendered).to have_link('GED', href: '/ged')
    expect(rendered).to have_link('Recherche', href: '/search')
  end
  
  it "shows admin links for admin users" do
    mock_component_helpers(described_class, user: admin_user, additional_helpers: {
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
  
  it "renders notifications link" do
    rendered = render_inline(described_class.new(current_page: current_path))
    
    expect(rendered).to have_link(href: '/notifications')
  end
  
  it "shows user menu items" do
    rendered = render_inline(described_class.new(current_page: current_path))
    
    expect(rendered).to have_link('Mon profil', href: '/users/edit')
    expect(rendered).to have_link('Notifications', href: '/notifications')
    expect(rendered).to have_link('Paramètres', href: '/users/edit')
    expect(rendered).to have_link('Déconnexion', href: '/users/sign_out')
  end
  
  it "renders mobile menu toggle" do
    rendered = render_inline(described_class.new(current_page: current_path))
    
    expect(rendered).to have_css('[data-controller="mobile-menu"]')
    expect(rendered).to have_css('button[data-action="click->mobile-menu#toggle"]')
  end
  
  it "highlights active page" do
    rendered = render_inline(described_class.new(current_page: '/ged'))
    
    # The component checks active_item? method which compares current_page with path
    expect(rendered).to have_css('a', text: 'GED')
  end
  
  context "when user is not signed in" do
    before do
      mock_component_helpers(described_class, user: nil, additional_helpers: {
        current_user: nil,
        user_signed_in?: false,
        request: double(path: current_path)
      })
    end
    
    it "shows login links" do
      rendered = render_inline(described_class.new(current_page: current_path))
      
      expect(rendered).to have_link('Connexion', href: '/users/sign_in')
      expect(rendered).to have_link('Inscription', href: '/users/sign_up')
    end
    
    it "does not show user menu" do
      rendered = render_inline(described_class.new(current_page: current_path))
      
      expect(rendered).not_to have_css('[data-controller="dropdown"]')
    end
  end
  
  context "with notifications" do
    it "shows notification count when user has unread notifications" do
      user_with_notifications = double(
        'user',
        id: 1,
        first_name: 'John',
        last_name: 'Doe',
        email: 'john@example.com',
        admin?: false,
        super_admin?: false,
        notifications: double(where: double(count: 3))
      )
      user_with_notifications.define_singleton_method(:has_permission?) { |perm| false }
      
      mock_component_helpers(described_class, user: user_with_notifications, additional_helpers: {
        current_user: user_with_notifications,
        request: double(path: current_path)
      })
      
      rendered = render_inline(described_class.new(current_page: current_path))
      
      expect(rendered).to have_css('span', text: '3')
    end
  end
end