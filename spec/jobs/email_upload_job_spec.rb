require 'rails_helper'

RSpec.describe EmailUploadJob, type: :job do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, email: 'test@example.com', organization: organization) }
  let(:space) { create(:space, organization: organization) }

  describe '#perform' do
    let(:params) do
      {
        to: 'upload+ABC123@docusphere.com',
        from: user.email,
        subject: 'Documents pour projet Alpha',
        attachments: ['rapport.pdf', 'annexe.docx']
      }
    end

    before do
      space # ensure space exists
    end

    it 'creates documents for each attachment' do
      expect {
        described_class.perform_now(**params)
      }.to change(Document, :count).by(2)
    end

    it 'creates documents with correct attributes' do
      described_class.perform_now(**params)
      
      document = Document.find_by(name: 'rapport.pdf')
      expect(document).to be_present
      expect(document.uploaded_by).to eq(user)
      expect(document.description).to include('Documents pour projet Alpha')
      expect(document.organization).to eq(organization)
    end

    it 'creates a notification for the user' do
      expect {
        described_class.perform_now(**params)
      }.to change(user.notifications, :count).by(1)
      
      notification = user.notifications.last
      expect(notification.title).to eq('Documents reçus par email')
      expect(notification.body).to include('2 nouveaux documents')
    end

    context 'when user not found' do
      let(:params) do
        {
          to: 'upload+ABC123@docusphere.com',
          from: 'unknown@example.com',
          subject: 'Test',
          attachments: ['test.pdf']
        }
      end

      it 'does not create documents' do
        expect {
          described_class.perform_now(**params)
        }.not_to change(Document, :count)
      end
    end

    context 'when no unique code in email' do
      let(:params) do
        {
          to: 'upload@docusphere.com',
          from: user.email,
          subject: 'Test',
          attachments: ['test.pdf']
        }
      end

      it 'does not create documents' do
        expect {
          described_class.perform_now(**params)
        }.not_to change(Document, :count)
      end
    end
  end
end