# frozen_string_literal: true

require "rails_helper"

RSpec.describe Documents::VersionComparisonComponent, type: :component do
  let(:user) { create(:user) }
  let(:document) { create(:document, :with_file) }
  
  # Create mock versions
  let!(:version1) do
    double("Version",
      id: 1,
      created_at: 2.days.ago,
      whodunnit: user.id.to_s,
      event: 'create',
      object_changes: {
        'title' => [nil, 'Initial Title'],
        'description' => [nil, 'Initial description']
      }
    )
  end
  
  let!(:version2) do
    double("Version",
      id: 2,
      created_at: 1.day.ago,
      whodunnit: user.id.to_s,
      event: 'update',
      object_changes: {
        'title' => ['Initial Title', 'Updated Title'],
        'description' => ['Initial description', 'Updated description'],
        'status' => ['draft', 'published']
      }
    )
  end

  let(:component) { described_class.new(document: document, version1: version1, version2: version2, current_user: user) }

  before do
    allow(document).to receive(:versions).and_return(double(order: [version2, version1]))
    allow(User).to receive(:find_by).with(id: user.id.to_s).and_return(user)
    allow_any_instance_of(described_class).to receive(:helpers).and_return(
      double(
        ged_compare_document_versions_path: "/compare/#{document.id}",
        restore_ged_document_version_path: ->(doc, version_id) { "/restore/#{doc.id}/#{version_id}" }
      )
    )
  end

  describe "#render" do
    context "with versions to compare" do
      it "renders the comparison header" do
        render_inline(component)
        
        expect(page).to have_text("Comparaison des versions")
      end

      it "renders version selectors" do
        render_inline(component)
        
        expect(page).to have_css('select[name="version1"]')
        expect(page).to have_css('select[name="version2"]')
        expect(page).to have_css('label', text: "Version antérieure")
        expect(page).to have_css('label', text: "Version récente")
      end

      it "renders version metadata" do
        render_inline(component)
        
        expect(page).to have_text("Par #{user.display_name}")
        expect(page).to have_text("Création")
        expect(page).to have_text("Modification")
      end

      it "renders field changes" do
        render_inline(component)
        
        expect(page).to have_text("Title")
        expect(page).to have_text("Description")
        expect(page).to have_text("Status")
      end

      it "highlights differences" do
        render_inline(component)
        
        expect(page).to have_css('del.text-red-600')
        expect(page).to have_css('ins.text-green-600')
      end

      it "renders navigation buttons" do
        render_inline(component)
        
        expect(page).to have_button("Version précédente")
        expect(page).to have_button("Version suivante")
      end

      it "renders restore button for non-create versions" do
        render_inline(component)
        
        expect(page).to have_link("Restaurer cette version")
      end

      it "has proper data attributes for JavaScript" do
        render_inline(component)
        
        expect(page).to have_css('[data-controller="version-comparison"]')
        expect(page).to have_css('[data-controller="version-selector"]')
        expect(page).to have_css('[data-action="change->version-selector#updateComparison"]')
      end

      it "formats dates properly" do
        render_inline(component)
        
        expect(page).to have_text(version1.created_at.strftime('%d/%m/%Y'))
        expect(page).to have_text(version2.created_at.strftime('%d/%m/%Y'))
      end
    end

    context "without versions to compare" do
      let(:component) { described_class.new(document: document, version1: nil, version2: nil, current_user: user) }

      before do
        allow(document).to receive(:versions).and_return(double(order: []))
      end

      it "renders empty state" do
        render_inline(component)
        
        expect(page).to have_text("Il n'y a pas suffisamment de versions")
        expect(page).to have_text("Au moins deux versions sont nécessaires")
      end

      it "does not render version selectors" do
        render_inline(component)
        
        expect(page).not_to have_css('select[name="version1"]')
        expect(page).not_to have_css('select[name="version2"]')
      end
    end

    context "with different field types" do
      let(:version_with_complex_changes) do
        double("Version",
          id: 3,
          created_at: Time.current,
          whodunnit: nil,
          event: 'update',
          object_changes: {
            'is_public' => [false, true],
            'expires_at' => [nil, Time.parse('2025-12-31')],
            'metadata' => [{}, { 'key' => 'value' }],
            'tags' => [['tag1'], ['tag1', 'tag2']]
          }
        )
      end

      let(:component) { described_class.new(document: document, version1: version1, version2: version_with_complex_changes, current_user: user) }

      it "formats boolean values" do
        render_inline(component)
        
        expect(page).to have_text("Non")
        expect(page).to have_text("Oui")
      end

      it "formats nil values" do
        render_inline(component)
        
        expect(page).to have_text("(vide)")
      end

      it "formats date values" do
        render_inline(component)
        
        expect(page).to have_text("31/12/2025")
      end

      it "shows system as author when whodunnit is nil" do
        render_inline(component)
        
        expect(page).to have_text("Par Système")
      end
    end

    context "version options" do
      let(:version3) do
        double("Version",
          id: 3,
          created_at: Time.current,
          whodunnit: user.id.to_s,
          event: 'update',
          object_changes: {}
        )
      end

      before do
        allow(document).to receive(:versions).and_return(double(order: [version3, version2, version1]))
      end

      it "renders all available versions in selects" do
        render_inline(component)
        
        expect(page).to have_css('option', count: 6) # 3 versions x 2 selects
      end

      it "formats version options with date" do
        render_inline(component)
        
        expect(page).to have_css('option', text: /Version \d+ - \d{2}\/\d{2}\/\d{4}/)
      end
    end

    context "excluded fields" do
      let(:version_with_system_fields) do
        double("Version",
          id: 4,
          created_at: Time.current,
          whodunnit: user.id.to_s,
          event: 'update',
          object_changes: {
            'title' => ['Old', 'New'],
            'updated_at' => [1.hour.ago, Time.current],
            'processing_metadata' => [{}, { 'processed' => true }]
          }
        )
      end

      let(:component) { described_class.new(document: document, version1: version1, version2: version_with_system_fields, current_user: user) }

      it "excludes system fields from display" do
        render_inline(component)
        
        expect(page).to have_text("Title")
        expect(page).not_to have_text("Updated at")
        expect(page).not_to have_text("Processing metadata")
      end
    end
  end
end