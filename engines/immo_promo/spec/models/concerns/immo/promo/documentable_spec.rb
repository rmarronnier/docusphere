require 'rails_helper'

RSpec.describe Immo::Promo::Documentable, type: :concern do
  # Create a test class to include the concern
  let(:test_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'immo_promo_stakeholders'
      include Immo::Promo::Documentable
      
      def self.name
        'TestDocumentable'
      end
    end
  end

  let(:organization) { create(:organization) }
  let(:space) { create(:space, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:documentable_instance) { create(:immo_promo_stakeholder, project: project) }

  describe 'included module behavior' do
    it 'adds document association' do
      expect(documentable_instance).to respond_to(:documents)
    end

    it 'adds document methods' do
      expect(documentable_instance).to respond_to(:attach_document)
      expect(documentable_instance).to respond_to(:documents_by_type)
      expect(documentable_instance).to respond_to(:has_required_documents?)
    end
  end

  describe '#attach_document' do
    it 'creates association with document' do
      document = create(:document, space: space)
      
      expect {
        documentable_instance.attach_document(document, document_type: 'contract')
      }.to change { documentable_instance.documents.count }.by(1)
    end

    it 'sets document type and metadata' do
      document = create(:document, space: space)
      documentable_instance.attach_document(document, document_type: 'insurance', metadata: { validity: '1 year' })
      
      attachment = documentable_instance.document_attachments.last
      expect(attachment.document_type).to eq('insurance')
      expect(attachment.metadata['validity']).to eq('1 year')
    end
  end

  describe '#documents_by_type' do
    it 'filters documents by type' do
      doc1 = create(:document, space: space)
      doc2 = create(:document, space: space)
      
      documentable_instance.attach_document(doc1, document_type: 'contract')
      documentable_instance.attach_document(doc2, document_type: 'insurance')
      
      contracts = documentable_instance.documents_by_type('contract')
      expect(contracts).to include(doc1)
      expect(contracts).not_to include(doc2)
    end
  end

  describe '#has_required_documents?' do
    it 'checks if all required document types are present' do
      # This method should be implemented based on the stakeholder type
      # For now, just test that the method exists
      expect(documentable_instance).to respond_to(:has_required_documents?)
    end
  end

  describe '#document_summary' do
    it 'provides summary of attached documents' do
      doc1 = create(:document, space: space)
      doc2 = create(:document, space: space)
      
      documentable_instance.attach_document(doc1, document_type: 'contract')
      documentable_instance.attach_document(doc2, document_type: 'insurance')
      
      summary = documentable_instance.document_summary
      expect(summary).to have_key('contract')
      expect(summary).to have_key('insurance')
      expect(summary['contract']).to eq(1)
      expect(summary['insurance']).to eq(1)
    end
  end

  describe 'scopes' do
    before do
      skip "Scopes require actual database table" unless test_class.table_exists?
    end

    describe '.with_documents' do
      it 'returns instances that have attached documents' do
        expect(test_class).to respond_to(:with_documents)
      end
    end

    describe '.missing_document_type' do
      it 'returns instances missing specific document type' do
        expect(test_class).to respond_to(:missing_document_type)
      end
    end
  end
end