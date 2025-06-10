require 'rails_helper'
require 'support/user_profile_helpers'

RSpec.describe Navigation::NavbarComponent, type: :component do
  let(:user) { create(:user) }
  let(:organization) { user.organization }
  let(:current_path) { '/' }
  
  before do
    mock_component_helpers(described_class, user: user, additional_helpers: {
      request: double(path: current_path)
    })
  end
  
  context 'with profile-based navigation' do
    context 'when user has direction profile' do
      before do
        setup_user_with_profile(user, 'direction')
      end
      
      it 'shows direction-specific navigation items' do
        rendered = render_inline(described_class.new(current_page: current_path))
        
        expect(rendered).to have_link('Vue d\'ensemble', href: '/dashboard/overview')
        expect(rendered).to have_link('Rapports stratégiques', href: '/reports/strategic')
        expect(rendered).to have_link('Validation documents', href: '/validations')
      end
    end
    
    context 'when user has chef_projet profile' do
      before do
        setup_user_with_profile(user, 'chef_projet')
      end
      
      it 'shows chef_projet-specific navigation items' do
        rendered = render_inline(described_class.new(current_page: current_path))
        
        expect(rendered).to have_link('Mes projets', href: '/immo/promo/projects')
        expect(rendered).to have_link('Tâches', href: '/tasks')
        expect(rendered).to have_link('Planning', href: '/planning')
      end
    end
    
    context 'when user has juriste profile' do
      before do
        setup_user_with_profile(user, 'juriste')
      end
      
      it 'shows juriste-specific navigation items' do
        rendered = render_inline(described_class.new(current_page: current_path))
        
        expect(rendered).to have_link('Documents juridiques', href: '/documents/legal')
        expect(rendered).to have_link('Contrats', href: '/contracts')
        expect(rendered).to have_link('Conformité', href: '/compliance')
      end
    end
  end
  
  context 'with profile switcher integration' do
    before do
      # Mock user with multiple profiles
      profiles = [
        OpenStruct.new(profile_type: 'direction', active: true),
        OpenStruct.new(profile_type: 'chef_projet', active: false)
      ]
      user.define_singleton_method(:user_profiles) { profiles }
      user.define_singleton_method(:current_profile) { profiles.first }
      user.define_singleton_method(:active_profile) { profiles.first }
    end
    
    it 'includes profile switcher component' do
      rendered = render_inline(described_class.new(current_page: current_path))
      
      expect(rendered).to have_css('.profile-switcher')
    end
  end
  
  context 'with quick access links' do
    before do
      setup_user_with_profile(user, 'direction')
    end
    
    it 'shows profile-specific quick links' do
      rendered = render_inline(described_class.new(current_page: current_path))
      
      # Quick links should be in dropdown or toolbar
      expect(rendered).to have_css('[data-quick-links]')
    end
  end
  
  context 'with breadcrumbs' do
    it 'shows breadcrumb navigation' do
      rendered = render_inline(described_class.new(
        current_page: '/ged/folders/123',
        breadcrumbs: [
          { label: 'GED', path: '/ged' },
          { label: 'Mes documents', path: '/ged/my-documents' },
          { label: 'Dossier projet' }
        ]
      ))
      
      expect(rendered).to have_css('[data-breadcrumbs]')
      expect(rendered).to have_link('GED', href: '/ged')
      expect(rendered).to have_link('Mes documents', href: '/ged/my-documents')
      expect(rendered).to have_text('Dossier projet')
    end
  end
  
  context 'when NavigationService is used' do
    it 'delegates navigation items to NavigationService' do
      navigation_service = instance_double(NavigationService)
      allow(NavigationService).to receive(:new).with(user).and_return(navigation_service)
      allow(navigation_service).to receive(:navigation_items).and_return([
        { label: 'Custom Item', path: '/custom', icon: 'star' }
      ])
      allow(navigation_service).to receive(:quick_links).and_return([])
      
      rendered = render_inline(described_class.new(current_page: current_path))
      
      expect(rendered).to have_link('Custom Item', href: '/custom')
    end
    
    it 'uses quick links from NavigationService' do
      navigation_service = instance_double(NavigationService)
      allow(NavigationService).to receive(:new).with(user).and_return(navigation_service)
      allow(navigation_service).to receive(:navigation_items).and_return([])
      allow(navigation_service).to receive(:quick_links).and_return([
        { title: 'Quick Action', link: '/quick', icon: 'lightning' }
      ])
      
      rendered = render_inline(described_class.new(current_page: current_path))
      
      expect(NavigationService).to have_received(:new).with(user)
    end
  end
end