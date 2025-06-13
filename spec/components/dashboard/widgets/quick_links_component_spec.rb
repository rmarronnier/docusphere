require 'rails_helper'

RSpec.describe Dashboard::Widgets::QuickLinksComponent, type: :component do
  let(:links) do
    [
      {
        name: 'Administration',
        path: '/admin',
        icon: 'cog',
        description: 'Gestion système'
      },
      {
        name: 'GED',
        path: '/ged',
        icon: 'folder',
        description: 'Gestion documentaire'
      },
      {
        name: 'Utilisateurs',
        path: '/users',
        icon: 'users',
        description: 'Gestion des utilisateurs de la plateforme'
      },
      {
        name: 'Rapports',
        path: '/reports',
        icon: 'chart-bar'
        # No description for this one
      }
    ]
  end

  describe "with links" do
    subject { render_inline(described_class.new(links: links)) }

    it "renders all links in grid layout" do
      expect(subject).to have_css(".grid.grid-cols-2.gap-3")
      expect(subject).to have_link("Administration", href: "/admin")
      expect(subject).to have_link("GED", href: "/ged")
      expect(subject).to have_link("Utilisateurs", href: "/users")
      expect(subject).to have_link("Rapports", href: "/reports")
    end

    it "displays link names" do
      expect(subject).to have_text("Administration")
      expect(subject).to have_text("GED")
      expect(subject).to have_text("Utilisateurs")
      expect(subject).to have_text("Rapports")
    end

    it "shows descriptions when available" do
      expect(subject).to have_text("Gestion système")
      expect(subject).to have_text("Gestion documentaire")
      expect(subject).to have_text("Gestion des utilisateurs de la plateforme")
    end

    it "handles missing descriptions gracefully" do
      # Should not crash when description is nil
      expect(subject).to have_text("Rapports")
    end

    it "renders icons with appropriate styling" do
      expect(subject).to have_css(".w-8.h-8.rounded-lg")
      expect(subject).to have_css(".text-gray-600") # cog icon
      expect(subject).to have_css(".text-yellow-600") # folder icon
      expect(subject).to have_css(".text-blue-600") # users icon
      expect(subject).to have_css(".text-green-600") # chart-bar icon
    end

    it "includes hover effects" do
      expect(subject).to have_css(".group")
      expect(subject).to have_css(".hover\\:border-gray-300")
      expect(subject).to have_css(".hover\\:shadow-sm")
      expect(subject).to have_css(".group-hover\\:scale-105")
    end
  end

  describe "without links" do
    subject { render_inline(described_class.new(links: [])) }

    it "shows empty state" do
      expect(subject).to have_css(".col-span-2")
      expect(subject).to have_css("svg")
      expect(subject).to have_text("Aucun lien rapide")
      expect(subject).to have_text("Les raccourcis apparaîtront ici")
    end

    it "does not show any links" do
      expect(subject).not_to have_link
    end
  end

  describe "with nil links" do
    subject { render_inline(described_class.new(links: nil)) }

    it "shows empty state" do
      expect(subject).to have_text("Aucun lien rapide")
    end
  end

  describe "icon color classes" do
    let(:component) { described_class.new(links: []) }

    it "returns correct color classes for different icons" do
      expect(component.send(:icon_color_class, 'cog')).to eq('text-gray-600 bg-gray-100')
      expect(component.send(:icon_color_class, 'users')).to eq('text-blue-600 bg-blue-100')
      expect(component.send(:icon_color_class, 'chart-bar')).to eq('text-green-600 bg-green-100')
      expect(component.send(:icon_color_class, 'folder')).to eq('text-yellow-600 bg-yellow-100')
      expect(component.send(:icon_color_class, 'search')).to eq('text-purple-600 bg-purple-100')
      expect(component.send(:icon_color_class, 'inbox')).to eq('text-indigo-600 bg-indigo-100')
      expect(component.send(:icon_color_class, 'user')).to eq('text-pink-600 bg-pink-100')
      expect(component.send(:icon_color_class, 'briefcase')).to eq('text-orange-600 bg-orange-100')
      expect(component.send(:icon_color_class, 'chart-line')).to eq('text-emerald-600 bg-emerald-100')
      expect(component.send(:icon_color_class, 'unknown')).to eq('text-gray-600 bg-gray-100')
    end
  end

  describe "grid layout" do
    it "maintains 2-column grid for different numbers of links" do
      # Test with 1 link
      single_link = [{ name: 'Test', path: '/test', icon: 'cog' }]
      result = render_inline(described_class.new(links: single_link))
      expect(result).to have_css(".grid.grid-cols-2")

      # Test with 3 links
      three_links = links.first(3)
      result = render_inline(described_class.new(links: three_links))
      expect(result).to have_css(".grid.grid-cols-2")
    end
  end
end