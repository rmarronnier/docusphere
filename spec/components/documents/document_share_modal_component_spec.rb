# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Documents::DocumentShareModalComponent, type: :component do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:document) { create(:document, organization: organization, uploaded_by: user) }
  let(:component) { described_class.new(document: document) }

  before do
    allow_any_instance_of(described_class).to receive(:helpers).and_return(
      double(
        current_user: user,
        policy: ->(_) { double(share?: true) },
        ged_document_document_shares_path: "/ged/documents/#{document.id}/document_shares"
      )
    )
  end

  describe '#initialize' do
    it 'sets document' do
      expect(component.document).to eq(document)
    end

    it 'generates default modal_id' do
      expect(component.modal_id).to eq("share-modal-#{document.id}")
    end

    it 'accepts custom modal_id' do
      custom_component = described_class.new(document: document, modal_id: 'custom-modal')
      expect(custom_component.modal_id).to eq('custom-modal')
    end
  end

  describe '#render?' do
    context 'when document is present and user can share' do
      it 'returns true' do
        expect(component.render?).to be true
      end
    end

    context 'when document is nil' do
      let(:component) { described_class.new(document: nil) }

      it 'returns false' do
        expect(component.render?).to be false
      end
    end

    context 'when user cannot share' do
      before do
        allow_any_instance_of(described_class).to receive(:helpers).and_return(
          double(
            current_user: user,
            policy: ->(_) { double(share?: false) }
          )
        )
      end

      it 'returns false' do
        expect(component.render?).to be false
      end
    end
  end

  describe 'rendering' do
    subject { render_inline(component) }

    it 'renders modal container' do
      expect(subject).to have_css('.share-modal')
      expect(subject).to have_css("#share-modal-#{document.id}")
    end

    it 'renders modal header with document title' do
      expect(subject).to have_content("Partager \"#{document.title}\"")
    end

    it 'renders close button' do
      expect(subject).to have_css('button[data-action="click->modal#close"]')
    end

    it 'renders share form' do
      expect(subject).to have_css('form[data-controller="document-share"]')
    end

    describe 'form fields' do
      it 'renders email input' do
        expect(subject).to have_field('Email', type: 'email')
        expect(subject).to have_css('input[required]')
        expect(subject).to have_css('input[placeholder="collegue@example.com"]')
      end

      it 'renders permission select' do
        expect(subject).to have_field('Permissions')
        expect(subject).to have_select('Permissions', options: [
          'Lecture seule',
          'Écriture',
          'Administration'
        ])
      end

      it 'renders message textarea' do
        expect(subject).to have_field('Message (optionnel)')
        expect(subject).to have_css('textarea[placeholder="Ajoutez un message pour le destinataire..."]')
      end

      it 'renders hidden document_id field' do
        expect(subject).to have_css("input[type='hidden'][value='#{document.id}']", visible: false)
      end
    end

    describe 'suggested users' do
      let!(:colleague1) { create(:user, organization: organization, first_name: 'John', last_name: 'Doe') }
      let!(:colleague2) { create(:user, organization: organization, first_name: 'Jane', last_name: 'Smith') }

      it 'displays suggested users from same organization' do
        expect(subject).to have_content('Suggestions rapides')
        expect(subject).to have_button('John Doe')
        expect(subject).to have_button('Jane Smith')
        expect(subject).to have_css('button[data-action="click->document-share#selectUser"]', count: 2)
      end

      it 'includes user email in data attribute' do
        expect(subject).to have_css("button[data-email='#{colleague1.email}']")
        expect(subject).to have_css("button[data-email='#{colleague2.email}']")
      end
    end

    describe 'recent shares' do
      let!(:share1) { create(:document_share, document: document, access_level: 'read') }
      let!(:share2) { create(:document_share, document: document, access_level: 'write') }

      before do
        # Force reload to pick up the shares
        document.reload
      end

      it 'displays recent shares' do
        expect(subject).to have_content('Partages récents')
        expect(subject).to have_content(share1.shared_with.display_name)
        expect(subject).to have_content(share2.shared_with.display_name)
      end

      it 'displays permission badges with correct styling' do
        expect(subject).to have_css('.bg-green-100.text-green-800', text: 'Read')
        expect(subject).to have_css('.bg-blue-100.text-blue-800', text: 'Write')
      end
    end

    it 'renders action buttons' do
      expect(subject).to have_button('Annuler')
      expect(subject).to have_button('Envoyer')
    end

    it 'renders success notification (hidden by default)' do
      expect(subject).to have_css('#share-success-notification.hidden')
      expect(subject).to have_content('Document partagé avec succès')
    end

    it 'sets up Stimulus controllers' do
      expect(subject).to have_css('[data-controller="modal"]')
      expect(subject).to have_css('[data-controller="document-share"]')
      expect(subject).to have_css('[data-controller="notification"]')
    end

    it 'configures keyboard shortcuts' do
      expect(subject).to have_css('[data-action*="keydown.esc@window->modal#close"]')
    end
  end

  describe 'permission_options' do
    it 'returns correct permission options' do
      expected_options = [
        ['Lecture seule', 'read'],
        ['Écriture', 'write'],
        ['Administration', 'admin']
      ]
      expect(component.send(:permission_options)).to eq(expected_options)
    end
  end

  describe 'permission_badge_classes' do
    it 'returns correct classes for each permission level' do
      expect(component.send(:permission_badge_classes, 'read')).to include('bg-green-100', 'text-green-800')
      expect(component.send(:permission_badge_classes, 'write')).to include('bg-blue-100', 'text-blue-800')
      expect(component.send(:permission_badge_classes, 'admin')).to include('bg-red-100', 'text-red-800')
      expect(component.send(:permission_badge_classes, 'unknown')).to include('bg-gray-100', 'text-gray-800')
    end
  end
end