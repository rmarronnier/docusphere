# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Navigation::NavbarComponent, type: :component do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:admin_user) { create(:user, role: 'admin', organization: organization) }
  let(:current_path) { '/' }
  
  before do
    mock_component_helpers(described_class, user: user, additional_helpers: {
      request: double(path: current_path),
      ged_document_path: ->(doc) { "/ged/documents/#{doc.id}" },
      validations_path: '/validations',
      compliance_dashboard_path: '/compliance',
      reports_path: '/reports',
      clients_path: '/clients',
      proposals_path: '/proposals',
      contracts_path: '/contracts',
      immo_promo_engine: double(projects_path: '/immo/promo/projects'),
      planning_path: '/planning',
      resources_path: '/resources',
      legal_contracts_path: '/legal/contracts',
      legal_deadlines_path: '/legal/deadlines',
      invoices_path: '/invoices',
      budget_dashboard_path: '/budget',
      expense_reports_path: '/expenses',
      specifications_path: '/specifications',
      technical_docs_path: '/technical_docs',
      support_tickets_path: '/support'
    })
  end
  
  it "renders navigation bar" do
    rendered = render_inline(described_class.new(current_page: current_path))
    
    expect(rendered).to have_css('nav')
    expect(rendered).to have_link('Docusphere', href: '/')
  end
  
  it "renders user menu when authenticated" do
    rendered = render_inline(described_class.new(current_page: current_path))
    
    expect(rendered).to have_css('[data-controller="dropdown"]')
    expect(rendered).to have_text(user.first_name&.first&.upcase || user.email.first.upcase)
  end
  
  it "renders search bar with contextual placeholder" do
    rendered = render_inline(described_class.new(current_page: current_path))
    
    expect(rendered).to have_css('form[action="/search"]')
    expect(rendered).to have_css('input[placeholder="Rechercher documents, dossiers, espaces..."]')
  end
  
  context "with profile-specific placeholders" do
    it "shows direction-specific search placeholder" do
      profile = create(:user_profile, user: user, profile_type: 'direction', is_active: true)
      user.update(active_profile: profile)
      
      rendered = render_inline(described_class.new(current_page: current_path))
      
      expect(rendered).to have_css('input[placeholder="Rechercher validations, rapports, documents..."]')
    end
    
    it "shows commercial-specific search placeholder" do
      profile = create(:user_profile, user: user, profile_type: 'commercial', is_active: true)
      user.update(active_profile: profile)
      
      rendered = render_inline(described_class.new(current_page: current_path))
      
      expect(rendered).to have_css('input[placeholder="Rechercher clients, propositions, contrats..."]')
    end
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
  
  context "with profile-specific navigation" do
    it "shows direction-specific navigation items" do
      profile = create(:user_profile, user: user, profile_type: 'direction', is_active: true)
      user.update(active_profile: profile)
      
      # Create some validation requests for badge count
      create_list(:validation_request, 3, assigned_to: user, status: 'pending')
      
      rendered = render_inline(described_class.new(current_page: current_path))
      
      expect(rendered).to have_link('Validations', href: '/validations')
      expect(rendered).to have_link('Conformité', href: '/compliance')
      expect(rendered).to have_link('Rapports', href: '/reports')
      
      # Check for badge
      expect(rendered).to have_css('span', text: '3')
    end
    
    it "shows chef_projet-specific navigation items" do
      profile = create(:user_profile, user: user, profile_type: 'chef_projet', is_active: true)
      user.update(active_profile: profile)
      
      rendered = render_inline(described_class.new(current_page: current_path))
      
      expect(rendered).to have_link('Mes projets', href: '/immo/promo/projects')
      expect(rendered).to have_link('Planning', href: '/planning')
      expect(rendered).to have_link('Ressources', href: '/resources')
    end
    
    it "shows commercial-specific navigation items" do
      profile = create(:user_profile, user: user, profile_type: 'commercial', is_active: true)
      user.update(active_profile: profile)
      
      rendered = render_inline(described_class.new(current_page: current_path))
      
      expect(rendered).to have_link('Clients', href: '/clients')
      expect(rendered).to have_link('Propositions', href: '/proposals')
      expect(rendered).to have_link('Contrats', href: '/contracts')
    end
  end
  
  it "renders notification bell component" do
    rendered = render_inline(described_class.new(current_page: current_path))
    
    expect(rendered).to have_css('[data-controller*="notification-bell"]')
  end
  
  it "renders recent items dropdown when available" do
    doc = create(:document, name: 'Recent Document')
    allow_any_instance_of(User).to receive(:accessible_documents).and_return(
      Document.where(id: doc.id)
    )
    
    rendered = render_inline(described_class.new(current_page: current_path))
    
    expect(rendered).to have_text('Récemment consultés')
    expect(rendered).to have_text('Recent Document')
  end
  
  it "shows user menu items with notification badge" do
    create_list(:notification, 5, user: user, read_at: nil)
    
    rendered = render_inline(described_class.new(current_page: current_path))
    
    within('[data-dropdown-target="menu"]') do
      expect(rendered).to have_link('Mon profil', href: '/users/edit')
      expect(rendered).to have_link('Notifications', href: '/notifications')
      expect(rendered).to have_css('span', text: '5')
      expect(rendered).to have_link('Paramètres', href: '/users/edit')
      expect(rendered).to have_link('Déconnexion', href: '/users/sign_out')
    end
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
  
  context "with badge counts" do
    it "shows compliance alerts count for juridique profile" do
      profile = create(:user_profile, user: user, profile_type: 'juridique', is_active: true)
      user.update(active_profile: profile)
      
      # Create expiring documents
      create_list(:document, 2, expiry_date: 15.days.from_now, status: 'active')
      
      # Create legal validation requests
      create_list(:validation_request, 3, 
        validation_type: 'legal', 
        status: 'pending', 
        assigned_to: user
      )
      
      rendered = render_inline(described_class.new(current_page: current_path))
      
      # Should show badge with count of 5 (2 expiring + 3 validations)
      within('.border-l.border-gray-200') do
        expect(rendered).to have_css('span', text: '5')
      end
    end
    
    it "shows new leads count for commercial profile" do
      profile = create(:user_profile, user: user, profile_type: 'commercial', is_active: true)
      user.update(active_profile: profile)
      
      # Create new leads from last 7 days
      create_list(:document, 4, document_type: 'lead', status: 'new', created_at: 3.days.ago)
      
      rendered = render_inline(described_class.new(current_page: current_path))
      
      within('.border-l.border-gray-200') do
        expect(rendered).to have_css('span', text: '4')
      end
    end
  end
end