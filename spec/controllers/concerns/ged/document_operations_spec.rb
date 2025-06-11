require 'rails_helper'

RSpec.describe Ged::DocumentOperations, type: :concern do
  let(:controller_class) do
    Class.new(ApplicationController) do
      include Ged::DocumentOperations
      
      def pundit_user
        @user
      end
      
      def set_user(user)
        @user = user
      end
    end
  end

  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:space) { create(:space, organization: organization) }
  let(:document) { create(:document, space: space, uploaded_by: user) }
  
  let(:controller) { controller_class.new }

  before do
    controller.set_user(user)
    allow(controller).to receive(:params).and_return(ActionController::Parameters.new({}))
    allow(controller).to receive(:render)
    allow(controller).to receive(:send_data)
    allow(controller).to receive(:redirect_to)
    allow(controller).to receive(:flash).and_return({})
  end

  describe '#download_document' do
    before do
      allow(controller).to receive(:params).and_return(
        ActionController::Parameters.new(id: document.id)
      )
      allow(controller).to receive(:policy_scope).with(Document).and_return(Document)
      allow(controller).to receive(:authorize)
      allow(controller).to receive(:rails_blob_url).and_return('http://example.com/download')
    end

    context 'when user has permission' do
      before do
        create(:authorization, 
          user: user,
          authorizable: document,
          permission: 'read'
        )
      end

      it 'sends the document file' do
        expect(controller).to receive(:redirect_to).with('http://example.com/download')
        controller.download_document
      end

      it 'logs the download activity' do
        expect(document).to receive(:increment_download_count!)
        allow(Document).to receive(:find).with(document.id).and_return(document)
        controller.download_document
      end
    end

    context 'when user lacks permission' do
      it 'redirects with error' do
        expect(controller).to receive(:authorize).and_raise(Pundit::NotAuthorizedError)
        expect { controller.download_document }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe '#preview_document' do
    before do
      allow(controller).to receive(:params).and_return(
        ActionController::Parameters.new(id: document.id)
      )
      allow(controller).to receive(:policy_scope).with(Document).and_return(Document)
      allow(controller).to receive(:authorize)
      allow(Document).to receive(:find).with(document.id).and_return(document)
    end

    context 'with previewable document' do
      before do
        create(:authorization, user: user, authorizable: document, permission: 'read')
        allow(document).to receive(:previewable?).and_return(true)
        allow(document).to receive(:increment_view_count!)
        allow(controller).to receive(:rails_blob_url).and_return('http://example.com/preview')
      end

      it 'renders the preview' do
        expect(controller).to receive(:redirect_to).with('http://example.com/preview')
        controller.preview_document
      end
    end
  end

  describe '#upload_document' do
    let(:file) { fixture_file_upload('spec/fixtures/sample.pdf', 'application/pdf') }
    let(:upload_params) do
      {
        document: {
          title: 'Test Document',
          description: 'Test Description',
          file: file,
          space_id: space.id
        }
      }
    end

    before do
      allow(controller).to receive(:params).and_return(
        ActionController::Parameters.new(upload_params)
      )
      allow(controller).to receive(:policy_scope).with(Space).and_return(Space)
      allow(controller).to receive(:authorize)
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:document_params).and_return(upload_params[:document])
      create(:authorization, user: user, authorizable: space, permission: 'write')
    end

    it 'creates new documents' do
      expect {
        controller.upload_document
      }.to change { Document.count }.by(1)
    end

    it 'processes documents in background' do
      expect(DocumentProcessingJob).to receive(:perform_later).with(kind_of(Document))
      controller.upload_document
    end
  end
end