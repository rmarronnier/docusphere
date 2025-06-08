require 'rails_helper'

RSpec.describe Documents::DocumentFormComponent, type: :component do
  let(:user) { create(:user) }
  let(:space) { create(:space, organization: user.organization) }
  let(:document) { build(:document, space: space) }
  
  before do
    mock_view_component_helpers(user: user)
  end
  
  describe "new document form" do
    it "renders form for new document" do
      render_inline(described_class.new(document: document))
      
      expect(page).to have_css('form.document-form')
      expect(page).to have_field('Titre')
      expect(page).to have_field('Description')
      expect(page).to have_field('Fichier')
      expect(page).to have_select('Espace')
      expect(page).to have_button('Créer')
    end
    
    it "includes file upload with drag and drop" do
      render_inline(described_class.new(document: document))
      
      expect(page).to have_css('[data-controller="file-upload"]')
      expect(page).to have_css('.drop-zone')
      expect(page).to have_content('Glissez-déposez votre fichier ici')
      expect(page).to have_css('input[type="file"]', visible: false)
    end
    
    it "shows file type restrictions" do
      render_inline(described_class.new(
        document: document,
        allowed_file_types: %w[pdf docx xlsx]
      ))
      
      expect(page).to have_content('Formats acceptés: PDF, DOCX, XLSX')
      expect(page).to have_css('input[accept=".pdf,.docx,.xlsx"]', visible: false)
    end
    
    it "shows max file size" do
      render_inline(described_class.new(
        document: document,
        max_file_size: 10.megabytes
      ))
      
      expect(page).to have_content('Taille maximale: 10 MB')
    end
  end
  
  describe "edit document form" do
    let(:existing_document) { create(:document, space: space, title: "Existing Doc") }
    
    it "renders form for existing document" do
      render_inline(described_class.new(document: existing_document))
      
      expect(page).to have_field('Titre', with: 'Existing Doc')
      expect(page).to have_button('Mettre à jour')
    end
    
    it "shows current file info" do
      existing_document.file.attach(
        io: StringIO.new("content"),
        filename: "current.pdf",
        content_type: "application/pdf"
      )
      
      render_inline(described_class.new(document: existing_document))
      
      expect(page).to have_content('Fichier actuel: current.pdf')
      expect(page).to have_css('.current-file-info')
    end
    
    it "allows replacing file" do
      existing_document.file.attach(
        io: StringIO.new("content"),
        filename: "current.pdf"
      )
      
      render_inline(described_class.new(document: existing_document))
      
      expect(page).to have_field('Remplacer le fichier')
      expect(page).to have_content('Laisser vide pour conserver le fichier actuel')
    end
  end
  
  describe "metadata fields" do
    let(:metadata_template) { create(:metadata_template, 
      organization: user.organization,
      fields: [
        { name: "client", label: "Client", type: "string", required: true },
        { name: "amount", label: "Montant", type: "number", required: false },
        { name: "category", label: "Catégorie", type: "select", options: ["A", "B", "C"] }
      ]
    )}
    
    it "renders metadata fields from template" do
      render_inline(described_class.new(
        document: document,
        metadata_template: metadata_template
      ))
      
      expect(page).to have_field('Client')
      expect(page).to have_css('input[required]', text: 'Client')
      expect(page).to have_field('Montant')
      expect(page).to have_select('Catégorie', options: ['', 'A', 'B', 'C'])
    end
    
    it "shows metadata section as collapsible" do
      render_inline(described_class.new(
        document: document,
        metadata_template: metadata_template
      ))
      
      expect(page).to have_css('[data-controller="collapse"]')
      expect(page).to have_content('Métadonnées')
      expect(page).to have_css('.metadata-fields')
    end
  end
  
  describe "tags input" do
    let!(:existing_tags) { create_list(:tag, 3, organization: user.organization) }
    
    it "renders tag selector" do
      render_inline(described_class.new(document: document, enable_tags: true))
      
      expect(page).to have_css('[data-controller="tag-input"]')
      expect(page).to have_field('Tags')
    end
    
    it "shows existing tags as suggestions" do
      render_inline(described_class.new(document: document, enable_tags: true))
      
      expect(page).to have_css('[data-tag-input-suggestions-value]')
      suggestions = page.find('[data-tag-input-suggestions-value]', visible: false)['data-tag-input-suggestions-value']
      expect(JSON.parse(suggestions)).to include(*existing_tags.map(&:name))
    end
    
    it "allows creating new tags" do
      render_inline(described_class.new(
        document: document,
        enable_tags: true,
        allow_new_tags: true
      ))
      
      expect(page).to have_css('[data-tag-input-allow-create-value="true"]', visible: false)
    end
  end
  
  describe "folder selection" do
    let!(:folders) { create_list(:folder, 3, space: space) }
    
    it "shows folder selector" do
      render_inline(described_class.new(document: document))
      
      expect(page).to have_select('Dossier')
      folders.each do |folder|
        expect(page).to have_css("option", text: folder.name)
      end
    end
    
    it "shows folder tree for nested folders" do
      parent = folders.first
      child = create(:folder, parent: parent, space: space, name: "Child")
      
      render_inline(described_class.new(document: document))
      
      expect(page).to have_css("option", text: "#{parent.name} / Child")
    end
  end
  
  describe "permissions" do
    it "shows permission settings for new documents" do
      render_inline(described_class.new(
        document: document,
        show_permissions: true
      ))
      
      expect(page).to have_css('.permissions-section')
      expect(page).to have_content('Permissions')
      expect(page).to have_field('Hériter les permissions du dossier')
    end
  end
  
  describe "form validation" do
    it "shows client-side validation attributes" do
      render_inline(described_class.new(document: document))
      
      expect(page).to have_css('input[name*="title"][required]')
      expect(page).to have_css('[data-controller*="form-validation"]')
    end
    
    it "shows error messages slot" do
      document.errors.add(:title, "ne peut pas être vide")
      document.errors.add(:file, "doit être fourni")
      
      render_inline(described_class.new(document: document))
      
      expect(page).to have_css('.form-errors')
      expect(page).to have_content("ne peut pas être vide")
      expect(page).to have_content("doit être fourni")
    end
  end
  
  describe "advanced options" do
    it "shows advanced options in collapsible section" do
      render_inline(described_class.new(
        document: document,
        show_advanced_options: true
      ))
      
      expect(page).to have_css('[data-controller="collapse"]')
      expect(page).to have_content('Options avancées')
      
      within '.advanced-options' do
        expect(page).to have_field('Activer l\'OCR')
        expect(page).to have_field('Extraire les métadonnées')
        expect(page).to have_field('Générer un aperçu')
      end
    end
  end
  
  describe "form actions" do
    it "shows appropriate buttons" do
      render_inline(described_class.new(document: document))
      
      expect(page).to have_button('Créer')
      expect(page).to have_link('Annuler')
    end
    
    it "shows save and continue button" do
      render_inline(described_class.new(
        document: document,
        show_save_and_continue: true
      ))
      
      expect(page).to have_button('Créer')
      expect(page).to have_button('Créer et continuer')
    end
  end
  
  describe "progress indicator" do
    it "shows upload progress bar" do
      render_inline(described_class.new(document: document))
      
      expect(page).to have_css('[data-file-upload-target="progressBar"]', visible: false)
      expect(page).to have_css('[data-file-upload-target="progressText"]', visible: false)
    end
  end
end