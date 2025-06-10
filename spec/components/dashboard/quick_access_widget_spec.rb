require 'rails_helper'

RSpec.describe Dashboard::QuickAccessWidget, type: :component do
  let(:user) { create(:user) }
  let(:organization) { user.organization }
  let(:widget_data) do
    {
      id: 4,
      type: 'quick_access',
      title: 'Accès rapide',
      config: {},
      data: { links: quick_links }
    }
  end
  
  context 'with quick links' do
    let(:quick_links) do
      [
        {
          id: 1,
          title: 'Nouveau document',
          description: 'Uploader un document',
          link: '/ged/upload',
          icon: 'document-add',
          color: 'blue'
        },
        {
          id: 2,
          title: 'Nouveau projet', 
          description: 'Créer un projet immobilier',
          link: '/immo/promo/projects/new',
          icon: 'folder-add',
          color: 'green'
        },
        {
          id: 3,
          title: 'Demande de validation',
          description: 'Soumettre un document',
          link: '/validations/new',
          icon: 'badge-check',
          color: 'purple'
        },
        {
          id: 4,
          title: 'Rapports',
          description: 'Tableaux de bord',
          link: '/reports',
          icon: 'chart-bar',
          color: 'orange'
        }
      ]
    end
    
    it 'renders quick access links' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_text('Accès rapide')
      expect(page).to have_text('Nouveau document')
      expect(page).to have_text('Nouveau projet')
      expect(page).to have_text('Demande de validation')
      expect(page).to have_text('Rapports')
    end
    
    it 'shows link descriptions' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_text('Uploader un document')
      expect(page).to have_text('Créer un projet immobilier')
      expect(page).to have_text('Soumettre un document')
      expect(page).to have_text('Tableaux de bord')
    end
    
    it 'includes proper links' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_link('Nouveau document', href: '/ged/upload')
      expect(page).to have_link('Nouveau projet', href: '/immo/promo/projects/new')
      expect(page).to have_link('Demande de validation', href: '/validations/new')
      expect(page).to have_link('Rapports', href: '/reports')
    end
    
    it 'shows icons for each link' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_css('[data-icon="document-add"]')
      expect(page).to have_css('[data-icon="folder-add"]')
      expect(page).to have_css('[data-icon="badge-check"]')
      expect(page).to have_css('[data-icon="chart-bar"]')
    end
    
    it 'applies color themes' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_css('[data-color="blue"]')
      expect(page).to have_css('[data-color="green"]')
      expect(page).to have_css('[data-color="purple"]')
      expect(page).to have_css('[data-color="orange"]')
    end
  end
  
  context 'without links' do
    let(:quick_links) { [] }
    
    it 'shows empty state' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_text('Aucun lien rapide configuré')
      expect(page).to have_css('.empty-state')
    end
  end
  
  context 'with loading state' do
    let(:quick_links) { [] }
    
    it 'shows loading skeleton' do
      render_inline(described_class.new(
        widget_data: widget_data.merge(loading: true), 
        user: user
      ))
      
      expect(page).to have_css('.loading-skeleton')
    end
  end
  
  context 'with custom layout' do
    let(:quick_links) do 
      Array.new(6) do |i|
        {
          id: i + 1,
          title: "Lien #{i + 1}",
          description: "Description #{i + 1}",
          link: "/link/#{i + 1}",
          icon: 'folder',
          color: 'gray'
        }
      end
    end
    
    it 'displays links in grid layout' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_css('.quick-link-item', count: 6)
      expect(page).to have_css('.grid')
    end
  end
  
  context 'with custom limit' do
    let(:quick_links) do 
      Array.new(10) do |i|
        {
          id: i + 1,
          title: "Lien #{i + 1}",
          description: "Description #{i + 1}",
          link: "/link/#{i + 1}",
          icon: 'folder',
          color: 'gray'
        }
      end
    end
    
    it 'respects the configured limit' do
      widget_data[:config][:limit] = 4
      
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_css('.quick-link-item', count: 4)
    end
  end
  
  context 'with custom columns' do
    let(:quick_links) do 
      Array.new(4) do |i|
        {
          id: i + 1,
          title: "Lien #{i + 1}",
          description: "Description #{i + 1}",
          link: "/link/#{i + 1}",
          icon: 'folder',
          color: 'gray'
        }
      end
    end
    
    it 'applies custom column configuration' do
      widget_data[:config][:columns] = 2
      
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_css('.grid-cols-2')
    end
  end
end