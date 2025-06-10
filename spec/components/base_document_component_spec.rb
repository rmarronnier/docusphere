require 'rails_helper'

RSpec.describe BaseDocumentComponent, type: :component do
  let(:user) { create(:user) }
  let(:space) { create(:space) }
  let(:document) { create(:document, space: space, uploaded_by: user) }
  let(:options) { {} }
  let(:component) { described_class.new(document: document, **options) }

  before do
    Current.user = user
  end

  describe '#initialize' do
    it 'sets default options' do
      expect(component.instance_variable_get(:@show_status)).to be true
      expect(component.instance_variable_get(:@show_metadata)).to be true
      expect(component.instance_variable_get(:@show_actions)).to be true
      expect(component.instance_variable_get(:@show_preview)).to be false
      expect(component.instance_variable_get(:@clickable)).to be true
    end

    context 'with custom options' do
      let(:options) { { show_status: false, show_preview: true } }

      it 'overrides defaults' do
        expect(component.instance_variable_get(:@show_status)).to be false
        expect(component.instance_variable_get(:@show_preview)).to be true
      end
    end
  end

  describe 'icon mapping' do
    described_class::DEFAULT_ICON_MAPPING.each do |ext, icon|
      context "for .#{ext} files" do
        it "returns #{icon} icon" do
          allow(document).to receive(:file_extension).and_return(".#{ext}")
          expect(component.send(:document_icon)).to eq icon
        end
      end
    end

    context 'for unknown extension' do
      it 'returns default icon' do
        allow(document).to receive(:file_extension).and_return('.xyz')
        expect(component.send(:document_icon)).to eq 'file'
      end
    end
  end

  describe 'status configuration' do
    described_class::DEFAULT_STATUS_CONFIG.each do |status, config|
      context "for #{status} status" do
        before { allow(document).to receive(:status).and_return(status) }

        it "returns correct configuration" do
          result = component.send(:status_config)
          expect(result[:color]).to eq config[:color]
          expect(result[:label]).to eq config[:label]
        end
      end
    end
  end

  describe '#render' do
    it 'renders document component' do
      render_inline(component)
      expect(page).to have_css('.document-component')
      expect(page).to have_text(document.title)
    end

    context 'with preview' do
      let(:options) { { show_preview: true } }

      before do
        allow(document).to receive_message_chain(:preview, :attached?).and_return(true)
      end

      it 'renders preview section' do
        render_inline(component)
        expect(page).to have_css('.document-preview')
      end
    end

    context 'with locked document' do
      before do
        allow(document).to receive(:locked?).and_return(true)
        allow(document).to receive(:locked_by).and_return(user)
      end

      it 'shows lock indicator' do
        render_inline(component)
        expect(page).to have_css('.fa-lock')
        expect(page).to have_text("Verrouillé par #{user.full_name}")
      end
    end

    context 'with tags' do
      let(:tag1) { create(:tag, name: 'Important') }
      let(:tag2) { create(:tag, name: 'Urgent') }

      before do
        document.tags << [tag1, tag2]
      end

      it 'renders tags' do
        render_inline(component)
        expect(page).to have_text('important')
        expect(page).to have_text('urgent')
      end
    end
  end

  describe 'permission helpers' do
    describe '#can_view?' do
      context 'when user can read document' do
        before { allow(document).to receive(:readable_by?).with(user).and_return(true) }

        it 'returns true' do
          expect(component.send(:can_view?)).to be true
        end
      end

      context 'when user cannot read document' do
        before { allow(document).to receive(:readable_by?).with(user).and_return(false) }

        it 'returns false' do
          expect(component.send(:can_view?)).to be false
        end
      end
    end

    describe '#can_edit?' do
      context 'when user can write to document' do
        before { allow(document).to receive(:writable_by?).with(user).and_return(true) }

        it 'returns true' do
          expect(component.send(:can_edit?)).to be true
        end
      end

      context 'when user cannot write to document' do
        before { allow(document).to receive(:writable_by?).with(user).and_return(false) }

        it 'returns false' do
          expect(component.send(:can_edit?)).to be false
        end
      end
    end
  end

  describe 'processing status helpers' do
    %w[processing failed completed].each do |status|
      describe "#processing_#{status}?" do
        it "returns true when status is #{status}" do
          allow(document).to receive(:processing_status).and_return(status)
          expect(component.send("processing_#{status}?")).to be true
        end

        it "returns false when status is not #{status}" do
          allow(document).to receive(:processing_status).and_return('other')
          expect(component.send("processing_#{status}?")).to be false
        end
      end
    end
  end

  describe '#document_url' do
    context 'when clickable is true' do
      it 'returns document path' do
        expect(component.send(:document_url)).to include("/ged/document/#{document.id}")
      end
    end

    context 'when clickable is false' do
      let(:options) { { clickable: false } }

      it 'returns #' do
        expect(component.send(:document_url)).to eq '#'
      end
    end

    context 'with polymorphic document' do
      let(:project) { create(:organization) } # Using any model as example
      before { allow(document).to receive(:documentable).and_return(project) }

      it 'returns polymorphic path' do
        expect(component.send(:document_url)).to include("/ged/document/#{document.id}")
      end
    end
  end
end