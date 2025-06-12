# frozen_string_literal: true

require "rails_helper"

RSpec.describe Documents::DocumentActionsDropdownComponent, type: :component do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:space) { create(:space, organization: organization) }
  let(:folder) { create(:folder, space: space) }
  let(:document) { create(:document, :with_file, space: space, folder: folder) }
  let(:component) { described_class.new(document: document, current_user: user) }

  before do
    allow_any_instance_of(described_class).to receive(:helpers).and_return(
      double(
        download_ged_document_path: "/download/#{document.id}",
        duplicate_ged_document_path: "/duplicate/#{document.id}",
        archive_ged_document_path: "/archive/#{document.id}",
        lock_ged_document_path: "/lock/#{document.id}",
        unlock_ged_document_path: "/unlock/#{document.id}",
        ged_document_path: "/documents/#{document.id}",
        move_ged_document_path: "/move/#{document.id}",
        request_validation_ged_document_path: "/request_validation/#{document.id}"
      )
    )
  end

  describe "#render" do
    context "with read permissions" do
      before do
        allow_any_instance_of(DocumentPolicy).to receive(:read?).and_return(true)
        allow_any_instance_of(DocumentPolicy).to receive(:update?).and_return(false)
        allow_any_instance_of(DocumentPolicy).to receive(:destroy?).and_return(false)
      end

      it "renders dropdown button" do
        render_inline(component)
        
        expect(page).to have_css('[data-controller="dropdown"]')
        expect(page).to have_css('[data-dropdown-target="button"]')
        expect(page).to have_css('[data-action="click->dropdown#toggle"]')
      end

      it "renders basic actions" do
        render_inline(component)
        
        expect(page).to have_link("Télécharger", href: "/download/#{document.id}")
        expect(page).to have_text("Imprimer")
        expect(page).to have_text("Générer lien public")
      end

      it "renders action icons" do
        render_inline(component)
        
        expect(page).to have_css('.ui-icon')
      end
    end

    context "with update permissions" do
      before do
        allow_any_instance_of(DocumentPolicy).to receive(:read?).and_return(true)
        allow_any_instance_of(DocumentPolicy).to receive(:update?).and_return(true)
        allow_any_instance_of(DocumentPolicy).to receive(:destroy?).and_return(false)
      end

      it "renders update actions" do
        render_inline(component)
        
        expect(page).to have_link("Dupliquer", href: "/duplicate/#{document.id}")
        expect(page).to have_text("Déplacer")
        expect(page).to have_link("Archiver", href: "/archive/#{document.id}")
      end

      it "renders turbo method attributes" do
        render_inline(component)
        
        expect(page).to have_css('[data-turbo-method="post"]')
        expect(page).to have_css('[data-turbo-method="patch"]')
      end

      it "renders confirmation dialogs" do
        render_inline(component)
        
        expect(page).to have_css('[data-turbo-confirm="Dupliquer ce document ?"]')
        expect(page).to have_css('[data-turbo-confirm="Archiver ce document ?"]')
      end
    end

    context "with lock permissions" do
      before do
        allow_any_instance_of(DocumentPolicy).to receive(:read?).and_return(true)
        allow_any_instance_of(DocumentPolicy).to receive(:lock?).and_return(true)
      end

      context "when document is not locked" do
        it "renders lock action" do
          render_inline(component)
          
          expect(page).to have_link("Verrouiller", href: "/lock/#{document.id}")
        end
      end

      context "when document is locked" do
        before { allow(document).to receive(:locked?).and_return(true) }

        it "renders unlock action" do
          render_inline(component)
          
          expect(page).to have_link("Déverrouiller", href: "/unlock/#{document.id}")
        end
      end
    end

    context "with validation permissions" do
      before do
        allow_any_instance_of(DocumentPolicy).to receive(:read?).and_return(true)
        allow_any_instance_of(DocumentPolicy).to receive(:request_validation?).and_return(true)
      end

      it "renders validation action" do
        render_inline(component)
        
        expect(page).to have_text("Demander validation")
        expect(page).to have_css('[data-action="click->document-actions#requestValidation"]')
      end
    end

    context "with destroy permissions" do
      before do
        allow_any_instance_of(DocumentPolicy).to receive(:read?).and_return(true)
        allow_any_instance_of(DocumentPolicy).to receive(:destroy?).and_return(true)
      end

      it "renders delete action with danger styling" do
        render_inline(component)
        
        expect(page).to have_link("Supprimer", href: "/documents/#{document.id}")
        expect(page).to have_css('.text-red-700')
        expect(page).to have_css('[data-turbo-method="delete"]')
        expect(page).to have_css('[data-turbo-confirm="Êtes-vous sûr de vouloir supprimer ce document ?"]')
      end
    end

    context "modals" do
      before do
        allow_any_instance_of(DocumentPolicy).to receive(:read?).and_return(true)
        allow_any_instance_of(DocumentPolicy).to receive(:update?).and_return(true)
        allow_any_instance_of(DocumentPolicy).to receive(:request_validation?).and_return(true)
      end

      it "renders move modal" do
        render_inline(component)
        
        expect(page).to have_css('#move-document-modal.hidden')
        expect(page).to have_text("Déplacer le document")
        expect(page).to have_css('form[action="/move/1"][method="post"]')
        expect(page).to have_css('select[name="folder_id"]')
      end

      it "renders request validation modal" do
        render_inline(component)
        
        expect(page).to have_css('#request-validation-modal.hidden')
        expect(page).to have_text("Demander une validation")
        expect(page).to have_css('form[action="/request_validation/1"][method="post"]')
        expect(page).to have_css('select[name="validator_id"]')
        expect(page).to have_css('textarea[name="message"]')
        expect(page).to have_css('input[name="due_date"][type="date"]')
      end
    end

    context "without user" do
      let(:component) { described_class.new(document: document, current_user: nil) }

      it "renders empty dropdown" do
        render_inline(component)
        
        expect(page).to have_css('[data-controller="dropdown"]')
        expect(page).not_to have_link("Télécharger")
        expect(page).not_to have_text("Imprimer")
      end
    end

    context "folder options" do
      let!(:other_folder) { create(:folder, space: space, name: "Other Folder") }
      
      before do
        allow_any_instance_of(DocumentPolicy).to receive(:read?).and_return(true)
        allow_any_instance_of(DocumentPolicy).to receive(:update?).and_return(true)
      end

      it "includes other folders in the same space" do
        render_inline(component)
        
        within('#move-document-modal') do
          expect(page).to have_css('option', text: other_folder.name)
        end
      end

      it "excludes current folder" do
        render_inline(component)
        
        within('#move-document-modal') do
          expect(page).not_to have_css('option', text: folder.name)
        end
      end
    end

    context "validator options" do
      let!(:other_user) { create(:user, organization: organization, first_name: "Jane", last_name: "Doe") }
      
      before do
        allow_any_instance_of(DocumentPolicy).to receive(:read?).and_return(true)
        allow_any_instance_of(DocumentPolicy).to receive(:request_validation?).and_return(true)
      end

      it "includes other active users from same organization" do
        render_inline(component)
        
        within('#request-validation-modal') do
          expect(page).to have_css('option', text: "Jane Doe")
        end
      end

      it "excludes current user" do
        render_inline(component)
        
        within('#request-validation-modal') do
          expect(page).not_to have_css('option', text: user.display_name)
        end
      end
    end
  end
end