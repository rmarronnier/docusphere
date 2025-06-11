require 'rails_helper'

RSpec.describe Ged::DocumentLocking, type: :controller do
  controller(ApplicationController) do
    include Ged::DocumentLocking
    
    def index
      render json: { status: 'ok' }
    end
  end

  let(:user) { create(:user) }
  let(:other_user) { create(:user, organization: user.organization) }
  let(:document) { create(:document, uploaded_by: user) }

  before do
    sign_in user
    controller.instance_variable_set(:@document, document)
  end

  describe '#lock_document' do
    context 'when document is not locked' do
      it 'locks the document successfully' do
        controller.params = { reason: 'Editing in progress' }
        allow(controller).to receive(:render)
        
        controller.lock_document
        
        expect(document.reload.locked?).to be true
        expect(document.locked_by).to eq(user)
        expect(document.lock_reason).to eq('Editing in progress')
      end
    end

    context 'when document is already locked by another user' do
      before do
        document.locked_by = other_user
        document.lock_reason = 'Other reason'
        document.lock!
      end

      it 'returns conflict error' do
        expect(controller).to receive(:render).with(
          json: hash_including(success: false, error: /déjà verrouillé/),
          status: :conflict
        )
        
        controller.lock_document
      end
    end

    context 'when document is locked by same user' do
      before do
        document.locked_by = user
        document.lock_reason = 'Previous reason'
        document.lock!
      end

      it 'updates the lock' do
        controller.params = { reason: 'New reason' }
        allow(controller).to receive(:render)
        
        controller.lock_document
        
        expect(document.reload.lock_reason).to eq('New reason')
      end
    end
  end

  describe '#unlock_document' do
    context 'when document is not locked' do
      it 'returns error' do
        expect(controller).to receive(:render).with(
          json: hash_including(success: false, error: 'Document non verrouillé'),
          status: :unprocessable_entity
        )
        
        controller.unlock_document
      end
    end

    context 'when document is locked by current user' do
      before do
        document.locked_by = user
        document.lock_reason = 'Test reason'
        document.lock!
      end

      it 'unlocks the document successfully' do
        expect(controller).to receive(:render).with(
          json: hash_including(success: true, message: /déverrouillé/)
        )
        
        controller.unlock_document
        
        expect(document.reload.locked?).to be false
      end
    end

    context 'when document is locked by another user' do
      before do
        document.locked_by = other_user
        document.lock_reason = 'Test reason'
        document.lock!
      end

      it 'returns forbidden error if user cannot force unlock' do
        # Create a document owned by other_user so current user is not the owner
        other_document = create(:document, uploaded_by: other_user)
        other_document.locked_by = other_user
        other_document.lock_reason = 'Test reason'
        other_document.lock!
        controller.instance_variable_set(:@document, other_document)
        
        allow(controller).to receive(:policy).and_return(double(force_unlock?: false))
        
        expect(controller).to receive(:render).with(
          json: hash_including(success: false, error: /ne pouvez pas déverrouiller/),
          status: :forbidden
        )
        
        controller.unlock_document
      end

      it 'unlocks if user can force unlock' do
        allow(controller).to receive(:policy).and_return(double(force_unlock?: true))
        allow(controller).to receive(:render)
        
        controller.unlock_document
        
        expect(document.reload.locked?).to be false
      end
    end
  end
end