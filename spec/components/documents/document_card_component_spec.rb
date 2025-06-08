require 'rails_helper'

RSpec.describe Documents::DocumentCardComponent, type: :component do
  let(:user) { create(:user) }
  let(:space) { create(:space, organization: user.organization) }
  let(:document) { create(:document, 
    title: "Test Document",
    description: "A test description",
    space: space,
    user: user,
    processing_status: 'completed'
  )}
  
  before do
    # Simuler l'utilisateur connecté pour les policies
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end
  
  it "renders document title" do
    render_inline(described_class.new(document: document))
    
    expect(page).to have_content("Test Document")
    expect(page).to have_link("Test Document", href: ged_document_path(document))
  end
  
  it "renders document metadata" do
    render_inline(described_class.new(document: document))
    
    expect(page).to have_content(user.full_name)
    expect(page).to have_content(space.name)
    expect(page).to have_content("A test description")
  end
  
  it "shows processing status badge" do
    document.update!(processing_status: 'processing')
    
    render_inline(described_class.new(document: document))
    
    expect(page).to have_css('.badge.processing')
    expect(page).to have_content("En cours de traitement")
  end
  
  it "shows virus warning for infected files" do
    document.update!(virus_scan_status: 'infected')
    
    render_inline(described_class.new(document: document))
    
    expect(page).to have_css('.alert-danger')
    expect(page).to have_content("Virus détecté")
  end
  
  it "renders action buttons based on permissions" do
    render_inline(described_class.new(document: document))
    
    expect(page).to have_link("Télécharger")
    expect(page).to have_link("Partager")
    expect(page).to have_link("Supprimer")
  end
  
  it "hides actions for users without permissions" do
    other_user = create(:user)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(other_user)
    
    render_inline(described_class.new(document: document))
    
    expect(page).not_to have_link("Supprimer")
  end
  
  describe "with tags" do
    let(:tag1) { create(:tag, name: "Important") }
    let(:tag2) { create(:tag, name: "Contrat") }
    
    before do
      document.tags << [tag1, tag2]
    end
    
    it "displays document tags" do
      render_inline(described_class.new(document: document))
      
      expect(page).to have_css('.tag', text: "Important")
      expect(page).to have_css('.tag', text: "Contrat")
    end
  end
  
  describe "hover interactions" do
    it "shows preview on hover when available" do
      document.preview.attach(
        io: File.open(Rails.root.join('spec/fixtures/preview.jpg')),
        filename: 'preview.jpg'
      )
      
      render_inline(described_class.new(document: document))
      
      expect(page).to have_css('[data-action="mouseenter->document-card#showPreview"]')
      expect(page).to have_css('.preview-container.hidden')
    end
  end
end