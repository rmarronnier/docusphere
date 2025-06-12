# frozen_string_literal: true

require "rails_helper"

RSpec.describe Documents::MetadataEditorComponent, type: :component do
  let(:user) { create(:user) }
  let(:document) { create(:document, :with_file, description: "Test description") }
  let(:tag1) { create(:tag, name: "important", organization: document.space.organization) }
  let(:tag2) { create(:tag, name: "urgent", organization: document.space.organization) }
  
  before do
    document.tags << [tag1, tag2]
    allow_any_instance_of(described_class).to receive(:helpers).and_return(
      double(
        update_metadata_ged_document_path: "/update_metadata/#{document.id}"
      )
    )
  end

  describe "view mode" do
    let(:component) { described_class.new(document: document, current_user: user, editing: false) }
    
    before do
      allow_any_instance_of(DocumentPolicy).to receive(:update?).and_return(true)
    end

    it "renders edit button when user can edit" do
      render_inline(component)
      
      expect(page).to have_button("Modifier")
      expect(page).to have_css('[data-action="click->metadata-editor#edit"]')
    end

    it "displays document description" do
      render_inline(component)
      
      expect(page).to have_text("Description")
      expect(page).to have_text("Test description")
    end

    it "displays document tags" do
      render_inline(component)
      
      expect(page).to have_text("Tags")
      expect(page).to have_text("important")
      expect(page).to have_text("urgent")
    end

    it "displays document type" do
      document.update(document_type: "contract")
      render_inline(component)
      
      expect(page).to have_text("Type de document")
      expect(page).to have_text("Contract")
    end

    it "displays expiration date" do
      document.update(expires_at: Date.new(2025, 12, 31))
      render_inline(component)
      
      expect(page).to have_text("Date d'expiration")
      expect(page).to have_text("31 décembre 2025")
    end

    it "shows empty state when no metadata" do
      document.update(description: nil)
      document.tags.clear
      
      render_inline(component)
      
      expect(page).to have_text("Aucune métadonnée définie")
    end

    context "without edit permission" do
      before do
        allow_any_instance_of(DocumentPolicy).to receive(:update?).and_return(false)
      end

      it "does not render edit button" do
        render_inline(component)
        
        expect(page).not_to have_button("Modifier")
      end

      it "still displays metadata" do
        render_inline(component)
        
        expect(page).to have_text("Test description")
        expect(page).to have_text("important")
      end
    end
  end

  describe "edit mode" do
    let(:component) { described_class.new(document: document, current_user: user, editing: true) }
    
    before do
      allow_any_instance_of(DocumentPolicy).to receive(:update?).and_return(true)
    end

    it "renders form" do
      render_inline(component)
      
      expect(page).to have_css('form[action="/update_metadata/1"]')
      expect(page).to have_css('[data-metadata-editor-target="form"]')
    end

    it "renders description field" do
      render_inline(component)
      
      expect(page).to have_field("Description", with: "Test description")
      expect(page).to have_css('textarea[name="document[description]"]')
    end

    it "renders tags field" do
      render_inline(component)
      
      expect(page).to have_field("Tags", with: "important, urgent")
      expect(page).to have_css('input[name="document[tags]"]')
      expect(page).to have_css('[data-controller="tag-input"]')
    end

    it "renders document type select" do
      render_inline(component)
      
      expect(page).to have_select("Type de document")
      expect(page).to have_css('option[value="invoice"]', text: "Facture")
      expect(page).to have_css('option[value="contract"]', text: "Contrat")
      expect(page).to have_css('option[value="report"]', text: "Rapport")
    end

    it "renders expiration date field" do
      render_inline(component)
      
      expect(page).to have_field("Date d'expiration")
      expect(page).to have_css('input[type="date"][name="document[expires_at]"]')
    end

    it "renders action buttons" do
      render_inline(component)
      
      expect(page).to have_button("Annuler")
      expect(page).to have_button("Enregistrer")
      expect(page).to have_css('[data-action="click->metadata-editor#cancel"]')
    end

    it "has proper form attributes" do
      render_inline(component)
      
      expect(page).to have_css('form[method="post"]')
      expect(page).to have_css('form[data-turbo-frame="_top"]')
      expect(page).to have_css('form[data-action="submit->metadata-editor#save"]')
    end

    context "with custom metadata fields" do
      let(:metadata_template) { create(:metadata_template) }
      let!(:text_field) { create(:metadata_field, metadata_template: metadata_template, name: "author", label: "Auteur", field_type: "text", required: true) }
      let!(:select_field) { create(:metadata_field, metadata_template: metadata_template, name: "category", label: "Catégorie", field_type: "select", options: ["A", "B", "C"]) }
      let!(:boolean_field) { create(:metadata_field, metadata_template: metadata_template, name: "approved", label: "Approuvé", field_type: "boolean") }
      
      before do
        document.update(
          metadata_template: metadata_template,
          metadata: { "author" => "John Doe", "category" => "B", "approved" => true }
        )
      end

      it "renders custom metadata section" do
        render_inline(component)
        
        expect(page).to have_text("Métadonnées personnalisées")
      end

      it "renders text field" do
        render_inline(component)
        
        expect(page).to have_field("Auteur", with: "John Doe")
        expect(page).to have_css('input[name="metadata[author]"][required]')
      end

      it "renders select field" do
        render_inline(component)
        
        expect(page).to have_select("Catégorie", selected: "B")
        expect(page).to have_css('option', text: "A")
        expect(page).to have_css('option', text: "C")
      end

      it "renders boolean field" do
        render_inline(component)
        
        expect(page).to have_field("Approuvé", checked: true)
        expect(page).to have_css('input[type="checkbox"][name="metadata[approved]"]')
      end
    end
  end

  describe "metadata field types" do
    let(:metadata_template) { create(:metadata_template) }
    let(:component) { described_class.new(document: document, current_user: user, editing: true) }
    
    before do
      allow_any_instance_of(DocumentPolicy).to receive(:update?).and_return(true)
      document.update(metadata_template: metadata_template)
    end

    it "renders textarea field" do
      create(:metadata_field, metadata_template: metadata_template, name: "notes", label: "Notes", field_type: "textarea")
      
      render_inline(component)
      
      expect(page).to have_css('textarea[name="metadata[notes]"]')
    end

    it "renders date field" do
      create(:metadata_field, metadata_template: metadata_template, name: "due_date", label: "Date limite", field_type: "date")
      
      render_inline(component)
      
      expect(page).to have_css('input[type="date"][name="metadata[due_date]"]')
    end

    it "renders number field" do
      create(:metadata_field, metadata_template: metadata_template, name: "amount", label: "Montant", field_type: "number")
      
      render_inline(component)
      
      expect(page).to have_css('input[type="number"][name="metadata[amount]"]')
    end

    it "falls back to text field for unknown types" do
      create(:metadata_field, metadata_template: metadata_template, name: "custom", label: "Custom", field_type: "unknown")
      
      render_inline(component)
      
      expect(page).to have_css('input[type="text"][name="metadata[custom]"]')
    end
  end

  describe "notification" do
    let(:component) { described_class.new(document: document, current_user: user, editing: false) }

    it "renders hidden notification div" do
      render_inline(component)
      
      expect(page).to have_css('#metadata-save-notification.hidden')
      expect(page).to have_css('[data-metadata-editor-target="notification"]')
      expect(page).to have_text("Métadonnées enregistrées avec succès")
    end
  end

  describe "data attributes" do
    let(:component) { described_class.new(document: document, current_user: user, editing: false) }

    it "sets document ID data attribute" do
      render_inline(component)
      
      expect(page).to have_css("[data-metadata-editor-document-id-value='#{document.id}']")
    end

    it "sets controller data attribute" do
      render_inline(component)
      
      expect(page).to have_css('[data-controller="metadata-editor"]')
    end
  end
end