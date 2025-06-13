require 'rails_helper'

RSpec.describe Dashboard::Widgets::MyDocumentsComponent, type: :component do
  let(:documents) do
    [
      {
        id: 1,
        title: "Document Test 1",
        space: "Espace Test",
        updated_at: 2.hours.ago,
        status: "active",
        tags: ["important", "contrat"],
        path: "/ged/documents/1"
      },
      {
        id: 2,
        title: "Document très long titre qui devrait être tronqué",
        space: "Autre Espace",
        updated_at: 1.day.ago,
        status: "locked",
        tags: ["rapport", "finance", "urgent", "confidential", "2023"],
        path: "/ged/documents/2"
      }
    ]
  end

  describe "with documents" do
    subject { render_inline(described_class.new(documents: documents)) }

    it "renders all documents" do
      expect(subject).to have_css(".space-y-3")
      expect(subject).to have_link("Document Test 1", href: "/ged/documents/1")
      expect(subject).to have_link(href: "/ged/documents/2")
    end

    it "shows document titles" do
      expect(subject).to have_text("Document Test 1")
      expect(subject).to have_text("Document très long titre")
    end

    it "displays space information" do
      expect(subject).to have_text("Espace Test")
      expect(subject).to have_text("Autre Espace")
    end

    it "shows status badges" do
      expect(subject).to have_css("span", text: "Actif")
      expect(subject).to have_css("span", text: "Verrouillé")
    end

    it "displays tags with limit" do
      # First document: 2 tags (all shown)
      expect(subject).to have_css("span", text: "important")
      expect(subject).to have_css("span", text: "contrat")
      
      # Second document: 5 tags (3 shown + "+2")
      expect(subject).to have_css("span", text: "rapport")
      expect(subject).to have_css("span", text: "finance")
      expect(subject).to have_css("span", text: "urgent")
      expect(subject).to have_css("span", text: "+2")
    end

    it "shows relative timestamps" do
      expect(subject).to have_text("aujourd'hui")
      expect(subject).to have_text("hier")
    end
  end

  describe "without documents" do
    subject { render_inline(described_class.new(documents: [])) }

    it "shows empty state" do
      expect(subject).to have_css("svg")
      expect(subject).to have_text("Aucun document")
      expect(subject).to have_text("Vos documents apparaîtront ici")
    end

    it "does not show document links" do
      expect(subject).not_to have_link(href: /\/ged\/documents\//)
    end
  end

  describe "with nil documents" do
    subject { render_inline(described_class.new(documents: nil)) }

    it "shows empty state" do
      expect(subject).to have_text("Aucun document")
    end
  end

  describe "status badge classes" do
    let(:component) { described_class.new(documents: []) }

    it "returns correct CSS classes for each status" do
      expect(component.send(:status_badge_class, 'draft')).to eq('bg-gray-100 text-gray-800')
      expect(component.send(:status_badge_class, 'active')).to eq('bg-green-100 text-green-800')
      expect(component.send(:status_badge_class, 'locked')).to eq('bg-yellow-100 text-yellow-800')
      expect(component.send(:status_badge_class, 'archived')).to eq('bg-blue-100 text-blue-800')
      expect(component.send(:status_badge_class, 'unknown')).to eq('bg-gray-100 text-gray-800')
    end
  end

  describe "status labels" do
    let(:component) { described_class.new(documents: []) }

    it "returns correct French labels for each status" do
      expect(component.send(:status_label, 'draft')).to eq('Brouillon')
      expect(component.send(:status_label, 'active')).to eq('Actif')
      expect(component.send(:status_label, 'locked')).to eq('Verrouillé')
      expect(component.send(:status_label, 'archived')).to eq('Archivé')
      expect(component.send(:status_label, nil)).to eq('Inconnu')
    end
  end

  describe "timestamp formatting" do
    let(:component) { described_class.new(documents: []) }

    it "formats recent timestamps correctly" do
      expect(component.send(:format_timestamp, 2.hours.ago)).to eq("aujourd'hui")
      expect(component.send(:format_timestamp, 1.day.ago)).to eq("hier")
      expect(component.send(:format_timestamp, 3.days.ago)).to eq("il y a 3 jours")
      expect(component.send(:format_timestamp, 1.week.ago)).to match(/\d{2}\/\d{2}\/\d{4}/)
      expect(component.send(:format_timestamp, nil)).to eq("à l'instant")
    end
  end
end