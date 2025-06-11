require 'rails_helper'

RSpec.describe VirusScanJob, type: :job do
  include ActiveJob::TestHelper
  
  let(:document) { create(:document, :with_pdf_file) }
  
  describe '#perform' do
    it 'enqueues the job with high priority' do
      expect {
        VirusScanJob.perform_later(document.id)
      }.to have_enqueued_job(VirusScanJob)
        .with(document.id)
        .on_queue('virus_scanning')
    end
    
    context 'when document exists' do
      before do
        allow(ClamAV::Client).to receive(:new).and_return(double(execute: true))
      end
      
      it 'scans document for viruses' do
        scanner = double('scanner')
        expect(ClamAV::Client).to receive(:new).and_return(scanner)
        expect(scanner).to receive(:execute).with(
          an_instance_of(ClamAV::Commands::ScanCommand)
        ).and_return(ClamAV::SuccessResponse.new('OK'))
        
        VirusScanJob.new.perform(document.id)
        
        expect(document.reload.virus_scan_status).to eq('scan_clean')
      end
      
      it 'quarantines infected files' do
        scanner = double('scanner')
        expect(ClamAV::Client).to receive(:new).and_return(scanner)
        expect(scanner).to receive(:execute).and_return(
          ClamAV::VirusResponse.new('stream: Win.Test.EICAR_HDB-1 FOUND')
        )
        
        expect(NotificationService).to receive(:notify_virus_detected).with(document)
        
        VirusScanJob.new.perform(document.id)
        
        expect(document.reload.virus_scan_status).to eq('scan_infected')
        expect(document.quarantined?).to be true
      end
      
      it 'updates scan timestamp' do
        VirusScanJob.new.perform(document.id)
        
        expect(document.reload.virus_scanned_at).to be_within(1.second).of(Time.current)
      end
      
      it 'handles multiple file attachments' do
        document.file.attach(io: File.open(Rails.root.join('spec/fixtures/sample.pdf')), filename: 'sample2.pdf')
        
        expect(ClamAV::Client).to receive(:new).twice.and_return(double(execute: ClamAV::SuccessResponse.new('OK')))
        
        VirusScanJob.new.perform(document.id)
      end
    end
    
    context 'when document does not exist' do
      it 'logs error and exits gracefully' do
        expect(Rails.logger).to receive(:error).with(/Document not found for virus scan/)
        
        VirusScanJob.new.perform(999999)
      end
    end
    
    context 'when ClamAV is not available' do
      it 'marks scan as failed and retries' do
        expect(ClamAV::Client).to receive(:new).and_raise(Errno::ECONNREFUSED)
        
        expect {
          VirusScanJob.new.perform(document.id)
        }.to raise_error(Errno::ECONNREFUSED)
        
        expect(document.reload.virus_scan_status).to eq('scan_error')
      end
      
      it 'notifies administrators of scan failures' do
        allow(ClamAV::Client).to receive(:new).and_raise(StandardError, 'ClamAV error')
        
        expect(NotificationService).to receive(:notify_scan_failure).with(
          document,
          'ClamAV error'
        )
        
        expect {
          VirusScanJob.new.perform(document.id)
        }.to raise_error(StandardError)
      end
    end
    
    context 'scan results' do
      let(:scanner) { double('scanner') }
      
      before do
        allow(ClamAV::Client).to receive(:new).and_return(scanner)
      end
      
      it 'handles clean scan results' do
        expect(scanner).to receive(:execute).and_return(
          ClamAV::SuccessResponse.new('stream: OK')
        )
        
        VirusScanJob.new.perform(document.id)
        
        expect(document.reload).to have_attributes(
          virus_scan_status: 'scan_clean',
          virus_name: nil,
          quarantined: false
        )
      end
      
      it 'handles infected scan results with virus details' do
        expect(scanner).to receive(:execute).and_return(
          ClamAV::VirusResponse.new('stream: Trojan.Generic FOUND')
        )
        
        VirusScanJob.new.perform(document.id)
        
        expect(document.reload).to have_attributes(
          virus_scan_status: 'scan_infected',
          virus_name: 'Trojan.Generic',
          quarantined: true
        )
      end
      
      it 'handles scan errors appropriately' do
        expect(scanner).to receive(:execute).and_return(
          ClamAV::ErrorResponse.new('ERROR: Could not scan file')
        )
        
        VirusScanJob.new.perform(document.id)
        
        expect(document.reload.virus_scan_status).to eq('scan_error')
      end
    end
    
    context 'performance and resource management' do
      it 'scans large files in chunks' do
        large_document = create(:document, file_size: 100.megabytes)
        
        expect_any_instance_of(VirusScanJob).to receive(:scan_in_chunks).with(large_document)
        
        VirusScanJob.new.perform(large_document.id)
      end
      
      it 'respects memory limits during scanning' do
        expect_any_instance_of(VirusScanJob).to receive(:within_memory_limit?).and_return(true)
        
        VirusScanJob.new.perform(document.id)
      end
      
      it 'releases file handles after scanning' do
        expect_any_instance_of(VirusScanJob).to receive(:cleanup_temp_files)
        
        VirusScanJob.new.perform(document.id)
      end
    end
    
    context 'integration with document workflow' do
      it 'blocks document access while scanning' do
        document.update!(virus_scan_status: 'scan_pending')
        
        expect(document.accessible?).to be false
        
        VirusScanJob.new.perform(document.id)
        
        expect(document.reload.accessible?).to be true
      end
      
      it 'triggers document reprocessing after clean scan' do
        expect(DocumentProcessingJob).to receive(:perform_later).with(document.id)
        
        VirusScanJob.new.perform(document.id)
      end
    end
  end
  
  describe 'ActiveJob configuration' do
    it 'uses the virus_scanning queue' do
      expect(VirusScanJob.new.queue_name).to eq('virus_scanning')
    end
    
    it 'has highest priority' do
      expect(VirusScanJob.priority).to eq(1)
    end
    
    it 'retries on connection failures' do
      expect(VirusScanJob.retry_on).to include(Errno::ECONNREFUSED)
    end
    
    it 'limits retry attempts' do
      expect(VirusScanJob.retry_on).to include(attempts: 3)
    end
  end
end