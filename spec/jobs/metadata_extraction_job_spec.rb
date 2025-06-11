require 'rails_helper'

RSpec.describe MetadataExtractionJob, type: :job do
  let(:document) { create(:document) }

  describe '#perform' do
    let(:processing_service) { instance_double(DocumentProcessingService) }

    before do
      allow(DocumentProcessingService).to receive(:new).with(document).and_return(processing_service)
    end

    it 'extracts metadata from document' do
      expect(processing_service).to receive(:extract_metadata).and_return({
        title: 'Contract Agreement',
        author: 'John Doe',
        created_date: '2024-01-15',
        pages: 10,
        word_count: 2500
      })

      MetadataExtractionJob.new.perform(document)
    end

    it 'updates document metadata field' do
      metadata = {
        author: 'Jane Smith',
        subject: 'Annual Report',
        keywords: ['finance', 'annual', 'report'],
        created_date: '2024-03-20',
        modified_date: '2024-03-25',
        pages: 45
      }

      allow(processing_service).to receive(:extract_metadata).and_return(metadata)

      MetadataExtractionJob.new.perform(document)
      document.reload

      expect(document.metadata['author']).to eq('Jane Smith')
      expect(document.metadata['subject']).to eq('Annual Report')
      expect(document.metadata['keywords']).to eq(['finance', 'annual', 'report'])
      expect(document.metadata['pages']).to eq(45)
    end

    context 'with PDF metadata' do
      before do
        allow(document).to receive(:content_type).and_return('application/pdf')
      end

      it 'extracts PDF-specific metadata' do
        pdf_metadata = {
          title: 'PDF Document',
          author: 'PDF Author',
          creator: 'Adobe Acrobat',
          producer: 'Adobe PDF Library',
          creation_date: '2024-01-01T10:00:00Z',
          modification_date: '2024-01-15T15:30:00Z',
          pages: 25,
          encrypted: false
        }

        allow(processing_service).to receive(:extract_metadata).and_return(pdf_metadata)

        MetadataExtractionJob.new.perform(document)
        document.reload

        expect(document.metadata).to include(pdf_metadata.stringify_keys)
      end
    end

    context 'with Office document metadata' do
      before do
        allow(document).to receive(:content_type).and_return('application/vnd.openxmlformats-officedocument.wordprocessingml.document')
      end

      it 'extracts Office-specific metadata' do
        office_metadata = {
          title: 'Business Plan',
          author: 'Corporate User',
          company: 'Acme Corp',
          manager: 'Manager Name',
          last_modified_by: 'Editor User',
          revision: 12,
          total_time: 480, # minutes
          words: 5000,
          characters: 30000
        }

        allow(processing_service).to receive(:extract_metadata).and_return(office_metadata)

        MetadataExtractionJob.new.perform(document)
        document.reload

        expect(document.metadata['company']).to eq('Acme Corp')
        expect(document.metadata['revision']).to eq(12)
        expect(document.metadata['words']).to eq(5000)
      end
    end

    context 'with image metadata' do
      before do
        allow(document).to receive(:content_type).and_return('image/jpeg')
      end

      it 'extracts EXIF metadata' do
        exif_metadata = {
          width: 3000,
          height: 2000,
          camera_make: 'Canon',
          camera_model: 'EOS R5',
          datetime: '2024-02-10 14:30:00',
          gps_latitude: 48.8566,
          gps_longitude: 2.3522,
          iso: 100,
          aperture: 'f/2.8',
          exposure_time: '1/500'
        }

        allow(processing_service).to receive(:extract_metadata).and_return(exif_metadata)

        MetadataExtractionJob.new.perform(document)
        document.reload

        expect(document.metadata['camera_make']).to eq('Canon')
        expect(document.metadata['gps_latitude']).to eq(48.8566)
        expect(document.metadata['iso']).to eq(100)
      end
    end

    it 'merges with existing metadata' do
      document.update!(metadata: { 'custom_field' => 'custom_value', 'author' => 'Old Author' })

      new_metadata = {
        author: 'New Author',
        pages: 15
      }

      allow(processing_service).to receive(:extract_metadata).and_return(new_metadata)

      MetadataExtractionJob.new.perform(document)
      document.reload

      expect(document.metadata['custom_field']).to eq('custom_value') # preserved
      expect(document.metadata['author']).to eq('New Author') # updated
      expect(document.metadata['pages']).to eq(15) # added
    end

    it 'calculates content hash' do
      allow(processing_service).to receive(:extract_metadata).and_return({})
      expect(processing_service).to receive(:calculate_content_hash).and_return('sha256:abcd1234')

      MetadataExtractionJob.new.perform(document)
      document.reload

      expect(document.metadata['content_hash']).to eq('sha256:abcd1234')
    end

    context 'when extraction fails' do
      before do
        allow(processing_service).to receive(:extract_metadata).and_raise(StandardError, 'Extraction failed')
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/Failed to extract metadata/)

        MetadataExtractionJob.new.perform(document)
      end

      it 'does not crash' do
        expect {
          MetadataExtractionJob.new.perform(document)
        }.not_to raise_error
      end

      it 'sets extraction error in metadata' do
        MetadataExtractionJob.new.perform(document)
        document.reload

        expect(document.metadata['extraction_error']).to be_present
        expect(document.metadata['extraction_attempted_at']).to be_present
      end
    end

    context 'with metadata template' do
      let(:template) { create(:metadata_template, name: 'Contract Template') }
      let!(:field1) { create(:metadata_field, metadata_template: template, name: 'contract_number', field_type: 'string') }
      let!(:field2) { create(:metadata_field, metadata_template: template, name: 'contract_date', field_type: 'date') }

      before do
        document.update!(metadata_template: template)
      end

      it 'creates document metadata records for template fields' do
        allow(processing_service).to receive(:extract_metadata).and_return({
          contract_number: 'CTR-2024-001',
          contract_date: '2024-01-15'
        })

        expect {
          MetadataExtractionJob.new.perform(document)
        }.to change { DocumentMetadata.count }.by(2)

        contract_number_metadata = DocumentMetadata.find_by(document: document, metadata_field: field1)
        expect(contract_number_metadata.value).to eq('CTR-2024-001')

        contract_date_metadata = DocumentMetadata.find_by(document: document, metadata_field: field2)
        expect(contract_date_metadata.value).to eq('2024-01-15')
      end
    end
  end

  describe 'job configuration' do
    it 'uses default queue' do
      expect(MetadataExtractionJob.new.queue_name).to eq('default')
    end

    it 'can be enqueued' do
      expect {
        MetadataExtractionJob.perform_later(document)
      }.to have_enqueued_job(MetadataExtractionJob).with(document)
    end
  end
end