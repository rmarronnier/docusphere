require 'rails_helper'

RSpec.describe Documents::DocumentViewerComponent, type: :component do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:space) { create(:space, organization: organization) }
  let(:document) { create(:document, space: space, uploaded_by: user) }
  
  before do
    allow_any_instance_of(Documents::DocumentViewerComponent).to receive(:helpers).and_return(
      double(
        current_user: user,
        policy: double(
          share?: true,
          update?: true,
          annotate?: true,
          export?: true
        ),
        rails_blob_path: '/blob/path',
        rails_representation_path: '/representation/path',
        number_to_human_size: '1.5 MB',
        time_ago_in_words: '2 days',
        ged_document_download_path: '/download',
        ged_download_document_path: '/download',
        ged_document_path: '/document',
        edit_ged_document_path: '/edit',
        new_ged_document_validation_request_path: '/validation/new',
        ged_document_versions_path: '/versions',
        ged_compare_document_versions_path: '/versions/compare',
        audit_trail_ged_document_path: '/audit',
        heroicon: '<svg></svg>'.html_safe
      )
    )
  end

  describe 'initialization' do
    it 'renders with required parameters' do
      component = described_class.new(document: document)
      
      expect(component).to be_a(described_class)
    end

    it 'accepts optional parameters' do
      component = described_class.new(
        document: document,
        show_actions: false,
        show_sidebar: false,
        context: :project
      )
      
      expect(component).to be_a(described_class)
    end
  end

  describe 'viewer content' do
    context 'with PDF document' do
      before do
        allow(document).to receive(:content_type_category).and_return(:pdf)
        allow(document).to receive(:pdf?).and_return(true)
      end

      it 'renders PDF viewer' do
        render_inline(described_class.new(document: document))
        
        expect(page).to have_css('.pdf-viewer-container')
        expect(page).to have_css('[data-controller="pdf-viewer"]')
        expect(page).to have_css('.pdf-toolbar')
      end
    end

    context 'with image document' do
      before do
        allow(document).to receive(:content_type_category).and_return(:image)
        allow(document).to receive(:image?).and_return(true)
      end

      it 'renders image viewer' do
        render_inline(described_class.new(document: document))
        
        expect(page).to have_css('.image-viewer-container')
        expect(page).to have_css('[data-controller="image-viewer"]')
        expect(page).to have_css('.image-toolbar')
      end
    end

    context 'with video document' do
      before do
        allow(document).to receive(:content_type_category).and_return(:video)
        allow(document).to receive(:video?).and_return(true)
        allow(document).to receive(:thumbnail_url).and_return('/thumbnail.jpg')
      end

      it 'renders video player' do
        render_inline(described_class.new(document: document))
        
        expect(page).to have_css('.video-player-container')
        expect(page).to have_css('video[controls]')
      end
    end

    context 'with text document' do
      before do
        allow(document).to receive(:content_type_category).and_return(:text)
        allow(document).to receive(:text?).and_return(true)
        allow(document.file).to receive(:download).and_return('Sample text content')
      end

      it 'renders text viewer' do
        render_inline(described_class.new(document: document))
        
        expect(page).to have_css('.text-viewer-container')
        expect(page).to have_css('[data-controller="text-viewer"]')
        expect(page).to have_css('.text-toolbar')
      end
    end

    context 'with unsupported format' do
      before do
        allow(document).to receive(:content_type_category).and_return(:unknown)
      end

      it 'renders fallback viewer' do
        render_inline(described_class.new(document: document))
        
        expect(page).to have_css('.fallback-viewer')
        expect(page).to have_text('Preview not available')
      end
    end
  end

  describe 'contextual actions' do
    let(:user_profile) { create(:user_profile, user: user, profile_type: profile_type) }
    
    before do
      allow(user).to receive(:active_profile).and_return(user_profile)
    end

    context 'for direction profile' do
      let(:profile_type) { 'direction' }

      it 'shows direction-specific actions' do
        allow_any_instance_of(Documents::DocumentViewerComponent).to receive(:policy).and_return(
          double(
            approve?: true,
            reject?: true,
            assign?: true
          )
        )
        
        render_inline(described_class.new(document: document, context: :direction))
        
        expect(page).to have_css('.contextual-actions')
        expect(page).to have_text('Approuver')
        expect(page).to have_text('Rejeter')
        expect(page).to have_text('Assigner')
      end
    end

    context 'for chef_projet profile' do
      let(:profile_type) { 'chef_projet' }

      it 'shows project manager actions' do
        allow_any_instance_of(Documents::DocumentViewerComponent).to receive(:policy).and_return(
          double(
            request_validation?: true,
            distribute?: true,
            link_to_project?: true
          )
        )
        allow(document).to receive(:project_linked?).and_return(false)
        
        render_inline(described_class.new(document: document, context: :chef_projet))
        
        expect(page).to have_css('.contextual-actions')
        expect(page).to have_text('Lier au projet')
        expect(page).to have_text('Demander validation')
      end
    end

    context 'for juriste profile' do
      let(:profile_type) { 'juriste' }

      it 'shows legal actions' do
        allow_any_instance_of(Documents::DocumentViewerComponent).to receive(:policy).and_return(
          double(
            validate_compliance?: true,
            annotate?: true,
            archive?: true
          )
        )
        
        render_inline(described_class.new(document: document, context: :juriste))
        
        expect(page).to have_css('.contextual-actions')
        expect(page).to have_text('Valider conformité')
        expect(page).to have_text('Note juridique')
      end
    end
  end

  describe 'sidebar' do
    it 'renders sidebar when show_sidebar is true' do
      render_inline(described_class.new(document: document, show_sidebar: true))
      
      expect(page).to have_css('[data-controller="document-sidebar"]')
      expect(page).to have_text('Information')
      expect(page).to have_text('Metadata')
      expect(page).to have_text('Activity')
    end

    it 'does not render sidebar when show_sidebar is false' do
      render_inline(described_class.new(document: document, show_sidebar: false))
      
      expect(page).not_to have_css('[data-controller="document-sidebar"]')
    end

    it 'shows versions tab when document has versions' do
      allow(document).to receive_message_chain(:versions, :any?).and_return(true)
      
      render_inline(described_class.new(document: document, show_sidebar: true))
      
      expect(page).to have_text('Versions')
    end
  end

  describe 'document header' do
    it 'displays document information' do
      allow(document).to receive(:title).and_return('Test Document.pdf')
      allow(document).to receive_message_chain(:uploaded_by, :display_name).and_return('John Doe')
      allow(document).to receive_message_chain(:folder, :name).and_return('Important Files')
      
      render_inline(described_class.new(document: document))
      
      expect(page).to have_text('Test Document.pdf')
      expect(page).to have_text('John Doe')
    end

    it 'shows locked status when document is locked' do
      allow(document).to receive(:locked?).and_return(true)
      
      render_inline(described_class.new(document: document))
      
      expect(page).to have_text('Locked')
    end
  end

  describe 'viewer actions' do
    it 'shows download button' do
      render_inline(described_class.new(document: document))
      
      expect(page).to have_text('Download')
    end

    it 'shows share button when user can share' do
      render_inline(described_class.new(document: document))
      
      expect(page).to have_text('Share')
    end

    it 'shows edit button when user can update' do
      render_inline(described_class.new(document: document))
      
      expect(page).to have_text('Edit')
    end

    it 'hides actions when show_actions is false' do
      render_inline(described_class.new(document: document, show_actions: false))
      
      expect(page).not_to have_css('.viewer-actions')
    end
  end
end