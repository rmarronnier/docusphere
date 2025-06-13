# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ged::DocumentCardComponent, type: :component do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:uploader) { create(:user, organization: organization) }
  let(:space) { create(:space, organization: organization) }
  let(:document) { create(:document, space: space, uploaded_by: uploader, title: "Test Document", description: "Test description") }
  let(:component) { described_class.new(document: document, current_user: user) }

  before do
    allow(component).to receive(:helpers).and_return(double(
      ged_document_path: "/ged/documents/#{document.id}",
      ged_download_document_path: "/ged/documents/#{document.id}/download",
      ged_edit_document_path: "/ged/documents/#{document.id}/edit",
      ged_duplicate_document_path: "/ged/documents/#{document.id}/duplicate",
      ged_archive_document_path: "/ged/documents/#{document.id}/archive",
      ged_lock_document_path: "/ged/documents/#{document.id}/lock",
      ged_unlock_document_path: "/ged/documents/#{document.id}/unlock",
      new_ged_document_document_share_path: "/ged/documents/#{document.id}/shares/new",
      heroicon: "<svg></svg>".html_safe,
      asset_path: "/assets/document-placeholder.png",
      rails_blob_path: "/rails/active_storage/blobs/test",
      rails_representation_path: "/rails/active_storage/representations/test",
      time_ago_in_words: "2 hours",
      l: "13/06/2025",
      t: "Published"
    ))
  end

  describe 'initialization' do
    it 'accepts required parameters' do
      expect(component.document).to eq(document)
      expect(component.current_user).to eq(user)
    end

    it 'accepts optional parameters' do
      component = described_class.new(
        document: document, 
        current_user: user, 
        show_preview: false,
        show_actions: false, 
        draggable: false,
        layout: :list
      )
      
      expect(component.show_preview).to be(false)
      expect(component.show_actions).to be(false)
      expect(component.draggable).to be(false)
      expect(component.layout).to eq(:list)
    end

    it 'sets default values for optional parameters' do
      expect(component.show_preview).to be(true)
      expect(component.show_actions).to be(true)
      expect(component.draggable).to be(true)
      expect(component.layout).to eq(:grid)
    end
  end

  describe 'rendering' do
    let(:rendered_component) { render_inline(component) }

    it 'renders the document card' do
      expect(rendered_component.to_html).to include('class')
      expect(rendered_component.to_html).to include('group')
    end

    it 'displays document title' do
      expect(rendered_component.text).to include(document.title)
    end

    it 'displays document description when present' do
      expect(rendered_component.text).to include(document.description)
    end

    context 'with grid layout' do
      it 'renders thumbnail area when show_preview is true' do
        expect(rendered_component.to_html).to include('relative')
      end

      it 'includes drag and drop attributes when draggable' do
        expect(rendered_component.to_html).to include('draggable="true"')
        expect(rendered_component.to_html).to include('document_id')
      end
    end

    context 'with list layout' do
      let(:component) { described_class.new(document: document, current_user: user, layout: :list) }
      let(:rendered_component) { render_inline(component) }

      it 'renders in list format' do
        expect(rendered_component.to_html).to include('px-4')
      end

      it 'displays uploader information' do
        expect(rendered_component.text).to include(uploader.display_name)
      end
    end

    context 'when document has no description' do
      let(:document) { create(:document, space: space, uploaded_by: uploader, title: "Test Document", description: nil) }

      it 'does not show description section' do
        expect(rendered_component.text).not_to include('Test description')
      end
    end
  end

  describe 'thumbnail and preview handling' do
    context 'when document has no file attached' do
      it 'returns icon fallback' do
        allow(document).to receive(:file).and_return(double(attached?: false))
        allow(document).to receive(:document_type).and_return('document')
        expect(component.send(:thumbnail_with_fallback)).to match(/bg-gradient-to-br/)
      end
    end

    context 'when document is an image' do
      before do
        filename = double(to_s: 'test.jpg')
        variant = double
        blob = double(byte_size: 1024, content_type: 'image/jpeg')
        file = double(attached?: true, blob: blob, filename: filename, variant: variant)
        allow(document).to receive(:file).and_return(file)
        allow(document).to receive(:image?).and_return(true)
        allow(document).to receive(:has_thumbnail?).and_return(false)
        allow(document).to receive(:document_type).and_return('image')
        allow(document).to receive(:file_extension).and_return('.jpg')
      end

      it 'returns image thumbnail' do
        allow(component).to receive(:image_tag).and_return('<img class="w-full h-full object-cover">'.html_safe)
        expect(component.send(:thumbnail_with_fallback)).to match(/object-cover/)
      end
    end

    context 'when document has thumbnail' do
      before do
        filename = double(to_s: 'test.pdf')
        blob = double(byte_size: 1024, content_type: 'application/pdf')
        file = double(attached?: true, blob: blob, filename: filename)
        allow(document).to receive(:file).and_return(file)
        allow(document).to receive(:has_thumbnail?).and_return(true)
        allow(document).to receive(:document_type).and_return('pdf')
        allow(document).to receive(:file_extension).and_return('.pdf')
      end

      it 'returns image thumbnail' do
        allow(component).to receive(:image_tag).and_return('<img class="w-full h-full object-cover">'.html_safe)
        expect(component.send(:thumbnail_with_fallback)).to match(/object-cover/)
      end
    end
  end

  describe 'file type detection and icons' do
    context 'for PDF documents' do
      before do
        allow(document).to receive(:document_type).and_return('pdf')
      end

      it 'returns correct icon' do
        expect(component.send(:document_icon)).to eq('document-text')
      end
    end

    context 'for Word documents' do
      before do
        allow(document).to receive(:document_type).and_return('word')
      end

      it 'returns correct icon' do
        expect(component.send(:document_icon)).to eq('document')
      end
    end

    context 'for image documents' do
      before do
        allow(document).to receive(:document_type).and_return('image')
      end

      it 'returns correct icon' do
        expect(component.send(:document_icon)).to eq('photograph')
      end
    end

    context 'for unknown document types' do
      before do
        allow(document).to receive(:document_type).and_return('unknown')
      end

      it 'returns default icon' do
        expect(component.send(:document_icon)).to eq('document')
      end
    end
  end

  describe 'status handling' do
    context 'when document is published' do
      before do
        document.update!(status: 'published')
      end

      it 'shows correct status badge' do
        expect(component.send(:status_badge_classes)).to include('bg-green-100 text-green-800')
        expect(component.send(:status_text)).to eq('Publié')
      end
    end

    context 'when document is draft' do
      before do
        document.update!(status: 'draft')
      end

      it 'shows correct status badge' do
        expect(component.send(:status_badge_classes)).to include('bg-gray-100 text-gray-800')
        expect(component.send(:status_text)).to eq('Brouillon')
      end
    end

    context 'when document is locked' do
      before do
        document.update!(status: 'locked')
      end

      it 'shows correct status badge' do
        expect(component.send(:status_badge_classes)).to include('bg-yellow-100 text-yellow-800')
        expect(component.send(:status_text)).to eq('Verrouillé')
      end
    end

    context 'when document is marked for deletion' do
      before do
        document.update!(status: 'marked_for_deletion')
      end

      it 'shows correct status badge' do
        expect(component.send(:status_badge_classes)).to include('bg-red-100 text-red-800')
        expect(component.send(:status_text)).to eq('À supprimer')
      end
    end
  end

  describe 'status indicators' do
    context 'when document is locked' do
      before do
        allow(document).to receive(:locked?).and_return(true)
      end

      it 'includes lock indicator' do
        indicators = component.send(:status_indicators)
        lock_indicator = indicators.find { |i| i[:icon] == 'lock-closed' }
        
        expect(lock_indicator).to be_present
        expect(lock_indicator[:color]).to eq('text-yellow-500')
        expect(lock_indicator[:title]).to eq('Document verrouillé')
      end
    end

    context 'when document is processing' do
      before do
        allow(document).to receive(:locked?).and_return(false)
        allow(document).to receive(:processing_status).and_return('processing')
      end

      it 'includes processing indicator' do
        indicators = component.send(:status_indicators)
        processing_indicator = indicators.find { |i| i[:icon] == 'arrow-path' }
        
        expect(processing_indicator).to be_present
        expect(processing_indicator[:color]).to eq('text-purple-500 animate-spin')
        expect(processing_indicator[:title]).to eq('Document en traitement')
      end
    end

    context 'when document has validation pending' do
      before do
        allow(document).to receive(:locked?).and_return(false)
        allow(document).to receive(:processing_status).and_return('completed')
        allow(document).to receive(:validation_pending?).and_return(true)
        allow(document).to receive(:validated?).and_return(false)
        allow(document).to receive(:validation_rejected?).and_return(false)
        document.update!(status: 'published')
      end

      it 'includes validation pending indicator' do
        indicators = component.send(:status_indicators)
        validation_indicator = indicators.find { |i| i[:icon] == 'clock' }
        
        expect(validation_indicator).to be_present
        expect(validation_indicator[:color]).to eq('text-orange-500')
        expect(validation_indicator[:title]).to eq('Validation en attente')
      end
    end
  end

  describe 'permissions and actions' do
    let(:document_policy) { double('DocumentPolicy') }

    before do
      allow(Pundit).to receive(:policy).with(user, document).and_return(document_policy)
      allow(document_policy).to receive(:read?).and_return(true)
    end

    context 'when user can read document' do
      it 'includes basic read actions' do
        allow(document_policy).to receive(:update?).and_return(false)
        allow(document_policy).to receive(:lock?).and_return(false)
        allow(document_policy).to receive(:request_validation?).and_return(false)
        allow(document_policy).to receive(:destroy?).and_return(false)
        
        # Mock file attachment with blob
        blob = double(byte_size: 1024, content_type: 'application/pdf')
        file = double(attached?: true, blob: blob)
        allow(document).to receive(:file).and_return(file)
        allow(document).to receive(:pdf?).and_return(false)
        allow(document).to receive(:image?).and_return(false)
        allow(document).to receive(:text?).and_return(false)

        actions = component.send(:document_actions)
        action_labels = actions.map { |a| a[:label] }
        
        expect(action_labels).to include("Voir", "Télécharger")
      end
    end

    context 'when user can update document' do
      before do
        allow(document_policy).to receive(:update?).and_return(true)
        allow(document_policy).to receive(:lock?).and_return(false)
        allow(document_policy).to receive(:request_validation?).and_return(false)
        allow(document_policy).to receive(:destroy?).and_return(false)
      end

      it 'includes edit and duplicate actions' do
        actions = component.send(:document_actions)
        action_labels = actions.map { |a| a[:label] }
        
        expect(action_labels).to include("Modifier", "Dupliquer", "Déplacer")
      end

      it 'includes archive action when document is not archived' do
        allow(document).to receive(:archived?).and_return(false)
        
        actions = component.send(:document_actions)
        action_labels = actions.map { |a| a[:label] }
        
        expect(action_labels).to include("Archiver")
      end
    end

    context 'when user can lock document' do
      before do
        allow(document_policy).to receive(:update?).and_return(false)
        allow(document_policy).to receive(:lock?).and_return(true)
        allow(document_policy).to receive(:request_validation?).and_return(false)
        allow(document_policy).to receive(:destroy?).and_return(false)
      end

      context 'when document is not locked' do
        before do
          allow(document).to receive(:locked?).and_return(false)
        end

        it 'includes lock action' do
          actions = component.send(:document_actions)
          action_labels = actions.map { |a| a[:label] }
          
          expect(action_labels).to include("Verrouiller")
        end
      end

      context 'when document is locked' do
        before do
          allow(document).to receive(:locked?).and_return(true)
        end

        it 'includes unlock action' do
          actions = component.send(:document_actions)
          action_labels = actions.map { |a| a[:label] }
          
          expect(action_labels).to include("Déverrouiller")
        end
      end
    end

    context 'when user can request validation' do
      before do
        allow(document_policy).to receive(:update?).and_return(false)
        allow(document_policy).to receive(:lock?).and_return(false)
        allow(document_policy).to receive(:request_validation?).and_return(true)
        allow(document_policy).to receive(:destroy?).and_return(false)
      end

      it 'includes validation request action' do
        actions = component.send(:document_actions)
        action_labels = actions.map { |a| a[:label] }
        
        expect(action_labels).to include("Demander validation")
      end
    end

    context 'when user can destroy document' do
      before do
        allow(document_policy).to receive(:update?).and_return(false)
        allow(document_policy).to receive(:lock?).and_return(false)
        allow(document_policy).to receive(:request_validation?).and_return(false)
        allow(document_policy).to receive(:destroy?).and_return(true)
      end

      it 'includes delete action' do
        actions = component.send(:document_actions)
        action_labels = actions.map { |a| a[:label] }
        
        expect(action_labels).to include("Supprimer")
      end

      it 'marks delete action as dangerous' do
        actions = component.send(:document_actions)
        delete_action = actions.find { |a| a[:label] == "Supprimer" }
        
        expect(delete_action[:danger]).to be(true)
      end
    end
  end

  describe 'quick actions' do
    let(:document_policy) { double('DocumentPolicy') }

    before do
      allow(Pundit).to receive(:policy).with(user, document).and_return(document_policy)
      allow(document_policy).to receive(:read?).and_return(true)
      allow(document_policy).to receive(:share?).and_return(false)
    end

    context 'when document has file attached' do
      before do
        blob = double(byte_size: 1024, content_type: 'application/pdf')
        file = double(attached?: true, blob: blob)
        allow(document).to receive(:file).and_return(file)
        allow(document).to receive(:pdf?).and_return(false)
        allow(document).to receive(:image?).and_return(false)
      end

      it 'includes download in quick actions' do
        quick_actions = component.send(:quick_actions)
        expect(quick_actions.any? { |a| a[:icon] == "arrow-down-tray" }).to be(true)
      end
    end

    context 'when document is previewable' do
      before do
        allow(document).to receive(:pdf?).and_return(true)
        allow(document).to receive(:image?).and_return(false)
      end

      it 'includes preview in quick actions' do
        quick_actions = component.send(:quick_actions)
        expect(quick_actions.any? { |a| a[:icon] == "magnifying-glass" }).to be(true)
      end
    end

    context 'when user can share document' do
      before do
        allow(document_policy).to receive(:share?).and_return(true)
      end

      it 'includes share in quick actions' do
        quick_actions = component.send(:quick_actions)
        expect(quick_actions.any? { |a| a[:icon] == "share" }).to be(true)
      end
    end
  end

  describe 'file size formatting' do
    context 'when document has no file' do
      before do
        allow(document).to receive(:file).and_return(double(attached?: false))
      end

      it 'returns nil' do
        expect(component.send(:file_size)).to be_nil
      end
    end

    context 'when document has small file' do
      before do
        blob = double(byte_size: 512)
        file = double(attached?: true, blob: blob)
        allow(document).to receive(:file).and_return(file)
      end

      it 'formats as bytes' do
        expect(component.send(:file_size)).to eq("512 B")
      end
    end

    context 'when document has medium file' do
      before do
        blob = double(byte_size: 2048)
        file = double(attached?: true, blob: blob)
        allow(document).to receive(:file).and_return(file)
      end

      it 'formats as kilobytes' do
        expect(component.send(:file_size)).to eq("2.0 KB")
      end
    end

    context 'when document has large file' do
      before do
        blob = double(byte_size: 2097152)
        file = double(attached?: true, blob: blob)
        allow(document).to receive(:file).and_return(file)
      end

      it 'formats as megabytes' do
        expect(component.send(:file_size)).to eq("2.0 MB")
      end
    end
  end

  describe 'CSS classes and styling' do
    context 'with grid layout' do
      it 'includes grid-specific classes' do
        expect(component.send(:card_classes)).to include('overflow-hidden shadow rounded-lg')
      end
    end

    context 'with list layout' do
      let(:component) { described_class.new(document: document, current_user: user, layout: :list) }

      it 'includes list-specific classes' do
        expect(component.send(:card_classes)).to include('border border-gray-200')
      end
    end

    it 'includes draggable class when draggable' do
      expect(component.send(:card_classes)).to include('draggable')
    end

    it 'excludes draggable class when not draggable' do
      component = described_class.new(document: document, current_user: user, draggable: false)
      expect(component.send(:card_classes)).not_to include('draggable')
    end
  end

  describe 'formatted dates' do
    context 'when document was updated recently' do
      before do
        document.update!(updated_at: 2.hours.ago)
      end

      it 'shows relative time with "ago" suffix' do
        result = component.send(:formatted_date)
        expect(result).to match(/ago$/)
        expect(result).to include("heure")
      end
    end

    context 'when document was updated long ago' do
      before do
        document.update!(updated_at: 2.weeks.ago)
      end

      it 'shows formatted date' do
        result = component.send(:formatted_date)
        expect(result).to match(/\d{2}\/\d{2}\/\d{4}|\d{1,2}\s\w+\s\d{2}:\d{2}/)
      end
    end
  end

  describe 'accessibility and user experience' do
    let(:rendered_component) { render_inline(component) }

    it 'includes proper link options with focus management' do
      link_options = component.send(:document_link_options)
      expect(link_options[:class]).to include('focus:ring-2')
    end

    context 'when show_actions is false' do
      let(:component) { described_class.new(document: document, current_user: user, show_actions: false) }
      let(:rendered_component) { render_inline(component) }

      it 'does not show action buttons' do
        expect(rendered_component.to_html).not_to include('data-dropdown-target="menu"')
      end
    end

    context 'when user is nil' do
      let(:component) { described_class.new(document: document, current_user: nil) }

      it 'handles missing user gracefully' do
        expect { component.send(:document_actions) }.not_to raise_error
        expect(component.send(:can?, :read, document)).to be(false)
      end
    end
  end

  describe 'error handling' do
    context 'when thumbnail generation fails' do
      before do
        allow(document).to receive(:file).and_return(double(attached?: true))
        allow(document).to receive(:has_thumbnail?).and_return(true)
        allow(component.helpers).to receive(:rails_blob_path).and_raise(StandardError, "Blob not found")
      end

      it 'falls back to placeholder' do
        expect(Rails.logger).to receive(:error).with(/Error generating thumbnail URL/)
        expect(component.send(:thumbnail_url)).to eq("/assets/document-placeholder.png")
      end
    end

    context 'when policy method does not exist' do
      let(:document_policy) { double('DocumentPolicy') }

      before do
        allow(Pundit).to receive(:policy).with(user, document).and_return(document_policy)
        allow(document_policy).to receive(:nonexistent_action?).and_raise(NoMethodError)
      end

      it 'returns false for missing policy methods' do
        expect(component.send(:can?, :nonexistent_action, document)).to be(false)
      end
    end
  end
end