require 'rails_helper'

RSpec.describe Documents::DocumentCardComponent, type: :component do
  let(:user) { create(:user) }
  let(:space) { create(:space, organization: user.organization) }
  let(:document) { create(:document, 
    title: "Test Document",
    description: "A test description",
    space: space,
    uploaded_by: user,
    processing_status: 'completed',
    status: 'published'
  )}
  
  before do
    mock_component_helpers(described_class, user: user, additional_helpers: {
      ged_document_path: ->(doc) { "/ged/documents/#{doc.id}" },
      download_ged_document_path: ->(doc) { "/ged/documents/#{doc.id}/download" },
      share_ged_document_path: ->(doc) { "/ged/documents/#{doc.id}/share" },
      image_tag: ->(src, options = {}) { "<img src='#{src}' #{options.map{|k,v| "#{k}='#{v}'"}.join(' ')}/>".html_safe },
      policy: ->(record) {
        double(
          update?: true,
          destroy?: true,
          share?: true
        )
      }
    })
  end
  
  it "renders document title" do
    rendered = render_inline(described_class.new(document: document))
    
    expect(rendered).to have_content("Test Document")
    expect(rendered).to have_link("Test Document")
  end
  
  it "renders document metadata" do
    rendered = render_inline(described_class.new(document: document))
    
    expect(rendered).to have_content("A test description")
    expect(rendered).to have_content("PDF")
    expect(rendered).to have_content("21 B") # File size
  end
  
  it "shows document status" do
    document.update!(status: 'archived')
    
    rendered = render_inline(described_class.new(document: document))
    
    expect(rendered).to have_content("Archivé")
  end
  
  it "renders document actions dropdown" do
    rendered = render_inline(described_class.new(document: document))
    
    expect(rendered).to have_css('[data-controller="dropdown"]')
    expect(rendered).to have_css('[data-action="click->dropdown#toggle"]')
  end
  
  it "renders action buttons based on permissions" do
    rendered = render_inline(described_class.new(document: document))
    
    expect(rendered).to have_link("Télécharger")
    expect(rendered).to have_link("Partager")
    expect(rendered).to have_link("Supprimer")
  end
  
  it "hides actions for users without permissions" do
    mock_component_helpers(described_class, user: user, additional_helpers: {
      ged_document_path: ->(doc) { "/ged/documents/#{doc.id}" },
      download_ged_document_path: ->(doc) { "/ged/documents/#{doc.id}/download" },
      share_ged_document_path: ->(doc) { "/ged/documents/#{doc.id}/share" },
      image_tag: ->(src, options = {}) { "<img src='#{src}' #{options.map{|k,v| "#{k}='#{v}'"}.join(' ')}/>".html_safe },
      policy: ->(record) {
        double(
          update?: false,
          destroy?: false,
          share?: false
        )
      }
    })
    
    rendered = render_inline(described_class.new(document: document))
    
    expect(rendered).not_to have_link("Supprimer")
    expect(rendered).not_to have_link("Modifier")
    expect(rendered).not_to have_link("Partager")
  end
  
  describe "with tags" do
    let(:tag1) { create(:tag, name: "Important") }
    let(:tag2) { create(:tag, name: "Contrat") }
    
    before do
      document.tags << [tag1, tag2]
    end
    
    it "displays document tags" do
      rendered = render_inline(described_class.new(document: document))
      
      expect(rendered).to have_content("Important")
      expect(rendered).to have_content("Contrat")
    end
  end
  
  describe "dropdown menu" do
    it "includes all action links" do
      rendered = render_inline(described_class.new(document: document))
      
      expect(rendered).to have_link("Voir")
      expect(rendered).to have_link("Modifier")
      expect(rendered).to have_link("Télécharger")
      expect(rendered).to have_link("Partager")
      expect(rendered).to have_link("Supprimer")
    end
  end
end