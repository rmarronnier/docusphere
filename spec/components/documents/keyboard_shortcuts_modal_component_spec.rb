# frozen_string_literal: true

require "rails_helper"

RSpec.describe Documents::KeyboardShortcutsModalComponent, type: :component do
  subject(:component) { described_class.new }

  describe "#render" do
    it "renders the modal container" do
      render_inline(component)
      
      expect(page).to have_css("#keyboard-shortcuts-modal")
      expect(page).to have_css('[data-controller="modal keyboard-shortcuts"]')
    end

    it "renders the modal header" do
      render_inline(component)
      
      expect(page).to have_text("Raccourcis clavier")
      expect(page).to have_css('[data-action="click->modal#close"]')
    end

    it "renders navigation shortcuts section" do
      render_inline(component)
      
      expect(page).to have_text("Navigation")
      expect(page).to have_text("Document précédent")
      expect(page).to have_text("Document suivant")
      expect(page).to have_text("Page précédente (PDF)")
      expect(page).to have_text("Page suivante (PDF)")
    end

    it "renders action shortcuts section" do
      render_inline(component)
      
      expect(page).to have_text("Actions")
      expect(page).to have_text("Télécharger le document")
      expect(page).to have_text("Imprimer le document")
      expect(page).to have_text("Partager le document")
      expect(page).to have_text("Éditer les métadonnées")
    end

    it "renders display shortcuts section" do
      render_inline(component)
      
      expect(page).to have_text("Affichage")
      expect(page).to have_text("Mode plein écran")
      expect(page).to have_text("Zoomer")
      expect(page).to have_text("Dézoomer")
      expect(page).to have_text("Réinitialiser le zoom")
    end

    it "renders system shortcuts section" do
      render_inline(component)
      
      expect(page).to have_text("Système")
      expect(page).to have_text("Afficher cette aide")
      expect(page).to have_text("Fermer les modales/plein écran")
    end

    it "renders keyboard keys as styled kbd elements" do
      render_inline(component)
      
      expect(page).to have_css("kbd", text: "D")
      expect(page).to have_css("kbd", text: "P")
      expect(page).to have_css("kbd", text: "F")
      expect(page).to have_css("kbd", text: "+")
      expect(page).to have_css("kbd", text: "-")
      expect(page).to have_css("kbd", text: "?")
      expect(page).to have_css("kbd", text: "ESC")
    end

    it "renders arrow keys properly" do
      render_inline(component)
      
      expect(page).to have_css("kbd", text: "←")
      expect(page).to have_css("kbd", text: "→")
      expect(page).to have_css("kbd", text: "↑")
      expect(page).to have_css("kbd", text: "↓")
    end

    it "has proper accessibility attributes" do
      render_inline(component)
      
      expect(page).to have_css('[data-action="keydown@window->keyboard-shortcuts#handleKeyPress"]')
    end

    it "renders footer with close instruction" do
      render_inline(component)
      
      expect(page).to have_text("Appuyez sur")
      expect(page).to have_text("pour fermer")
      within(".bg-gray-50") do
        expect(page).to have_css("kbd", text: "ESC")
      end
    end

    it "has responsive grid layout" do
      render_inline(component)
      
      expect(page).to have_css(".grid.grid-cols-1.sm\\:grid-cols-2")
    end

    it "is hidden by default" do
      render_inline(component)
      
      expect(page).to have_css("#keyboard-shortcuts-modal.hidden")
    end
  end
end