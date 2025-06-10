require 'rails_helper'

RSpec.describe NavigationService, type: :service do
  let(:user) { create(:user) }
  let(:profile) { create(:user_profile, user: user, profile_type: profile_type) }
  let(:service) { described_class.new(user) }
  
  before do
    user.active_profile = profile
    user.save
  end

  describe '#navigation_items' do
    context 'for direction profile' do
      let(:profile_type) { 'direction' }
      
      it 'returns direction-specific navigation items' do
        items = service.navigation_items
        
        expect(items).to be_an(Array)
        expect(items).to include(
          hash_including(
            name: 'Tableau de bord',
            path: '/dashboard',
            icon: 'home'
          )
        )
        expect(items).to include(
          hash_including(
            name: 'Portefeuille projets',
            path: '/immo/promo/projects',
            icon: 'briefcase'
          )
        )
        expect(items).to include(
          hash_including(
            name: 'Validations',
            path: '/validations',
            icon: 'check-circle'
          )
        )
      end
      
      it 'includes submenu items for complex sections' do
        items = service.navigation_items
        projects_item = items.find { |i| i[:name] == 'Portefeuille projets' }
        
        expect(projects_item[:children]).to be_present
        expect(projects_item[:children]).to include(
          hash_including(name: 'Vue d\'ensemble', path: '/immo/promo/projects')
        )
      end
    end
    
    context 'for chef_projet profile' do
      let(:profile_type) { 'chef_projet' }
      
      it 'returns project manager navigation items' do
        items = service.navigation_items
        
        expect(items).to include(
          hash_including(
            name: 'Mes projets',
            path: '/immo/promo/projects',
            icon: 'folder'
          )
        )
        expect(items).to include(
          hash_including(
            name: 'Planning',
            path: '/immo/promo/coordination',
            icon: 'calendar'
          )
        )
      end
      
      it 'does not include direction-only items' do
        items = service.navigation_items
        
        expect(items).not_to include(
          hash_including(name: 'Portefeuille projets')
        )
      end
    end
    
    context 'for juriste profile' do
      let(:profile_type) { 'juriste' }
      
      it 'returns legal-specific navigation items' do
        items = service.navigation_items
        
        expect(items).to include(
          hash_including(
            name: 'Dossiers juridiques',
            path: '/ged/folders/legal',
            icon: 'scale'
          )
        )
        expect(items).to include(
          hash_including(
            name: 'Autorisations',
            path: '/immo/promo/permits',
            icon: 'document-text'
          )
        )
      end
    end
    
    context 'for commercial profile' do
      let(:profile_type) { 'commercial' }
      
      it 'returns sales-specific navigation items' do
        items = service.navigation_items
        
        expect(items).to include(
          hash_including(
            name: 'Tableau commercial',
            path: '/immo/promo/commercial-dashboard',
            icon: 'trending-up'
          )
        )
      end
    end
    
    context 'for unknown profile' do
      let(:profile_type) { 'assistant_rh' }
      
      it 'returns default navigation items' do
        items = service.navigation_items
        
        expect(items).to include(
          hash_including(
            name: 'Tableau de bord',
            path: '/dashboard'
          )
        )
        expect(items).to include(
          hash_including(
            name: 'Documents',
            path: '/ged'
          )
        )
      end
    end
  end
  
  describe '#quick_links' do
    let(:profile_type) { 'chef_projet' }
    
    it 'returns frequently used links for the profile' do
      links = service.quick_links
      
      expect(links).to be_an(Array)
      expect(links.size).to be <= 6
      expect(links.first).to include(:name, :path, :icon, :color)
    end
  end
  
  describe '#breadcrumb_for' do
    let(:profile_type) { 'direction' }
    
    it 'generates breadcrumb trail for a given path' do
      breadcrumb = service.breadcrumb_for('/immo/promo/projects/123/phases')
      
      expect(breadcrumb).to be_an(Array)
      expect(breadcrumb).to include(
        hash_including(name: 'Accueil', path: '/')
      )
      expect(breadcrumb.last[:name]).to eq('Phases')
      expect(breadcrumb.last[:current]).to be true
    end
  end
  
  describe '#can_access?' do
    let(:profile_type) { 'chef_projet' }
    
    it 'checks if profile can access a specific path' do
      expect(service.can_access?('/immo/promo/projects')).to be true
      expect(service.can_access?('/immo/promo/financial-dashboard')).to be false
    end
  end
end