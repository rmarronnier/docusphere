require 'rails_helper'

RSpec.describe Documents::VirusScannable do
  let(:document) { create(:document) }

  describe 'virus scanning' do
    it 'has default virus scan status of pending' do
      expect(document.virus_scan_status).to eq('pending')
    end

    describe '#mark_virus_scan_started!' do
      it 'updates status to scanning' do
        document.mark_virus_scan_started!
        expect(document.virus_scan_status).to eq('scanning')
        expect(document.virus_scanned_at).to be_nil
      end
    end

    describe '#mark_virus_scan_clean!' do
      it 'updates status to clean' do
        document.mark_virus_scan_clean!
        expect(document.virus_scan_status).to eq('clean')
        expect(document.virus_scanned_at).to be_present
      end

      it 'clears any quarantine flag' do
        document.quarantined = true
        document.mark_virus_scan_clean!
        expect(document.quarantined?).to be false
      end
    end

    describe '#mark_virus_scan_infected!' do
      it 'updates status to infected' do
        threat = 'Trojan.Generic'
        document.mark_virus_scan_infected!(threat)
        expect(document.virus_scan_status).to eq('infected')
        expect(document.virus_scan_result).to eq(threat)
        expect(document.virus_scanned_at).to be_present
      end

      it 'quarantines the document' do
        document.mark_virus_scan_infected!('Malware')
        expect(document.quarantined?).to be true
        expect(document.quarantined_at).to be_present
      end

      it 'triggers infection notification' do
        expect(NotificationService).to receive(:notify_virus_detected).with(document)
        document.mark_virus_scan_infected!('Virus')
      end
    end

    describe '#mark_virus_scan_error!' do
      it 'updates status to error' do
        error = 'Scanner unavailable'
        document.mark_virus_scan_error!(error)
        expect(document.virus_scan_status).to eq('error')
        expect(document.virus_scan_result).to eq(error)
      end
    end

    describe '#virus_scan_clean?' do
      it 'returns true when clean' do
        document.virus_scan_status = 'clean'
        expect(document.virus_scan_clean?).to be true
      end

      it 'returns false when not clean' do
        document.virus_scan_status = 'infected'
        expect(document.virus_scan_clean?).to be false
      end
    end

    describe '#virus_scan_pending?' do
      it 'returns true when pending' do
        expect(document.virus_scan_pending?).to be true
      end

      it 'returns false when scanned' do
        document.virus_scan_status = 'clean'
        expect(document.virus_scan_pending?).to be false
      end
    end

    describe '#requires_virus_scan?' do
      it 'returns true for executable files' do
        allow(document).to receive(:content_type).and_return('application/x-msdownload')
        expect(document.requires_virus_scan?).to be true
      end

      it 'returns true for office documents' do
        allow(document).to receive(:content_type).and_return('application/vnd.openxmlformats-officedocument.wordprocessingml.document')
        expect(document.requires_virus_scan?).to be true
      end

      it 'returns false for safe file types' do
        allow(document).to receive(:content_type).and_return('text/plain')
        expect(document.requires_virus_scan?).to be false
      end

      it 'returns false when no file attached' do
        allow(document.file).to receive(:attached?).and_return(false)
        expect(document.requires_virus_scan?).to be false
      end
    end

    describe '#safe_to_download?' do
      it 'returns true when scan is clean' do
        document.virus_scan_status = 'clean'
        expect(document.safe_to_download?).to be true
      end

      it 'returns false when infected' do
        document.virus_scan_status = 'infected'
        expect(document.safe_to_download?).to be false
      end

      it 'returns false when scan pending and scan required' do
        allow(document).to receive(:requires_virus_scan?).and_return(true)
        expect(document.safe_to_download?).to be false
      end

      it 'returns true when scan not required' do
        allow(document).to receive(:requires_virus_scan?).and_return(false)
        expect(document.safe_to_download?).to be true
      end
    end

    describe '#quarantine!' do
      it 'quarantines the document' do
        document.quarantine!
        expect(document.quarantined?).to be true
        expect(document.quarantined_at).to be_present
      end

      it 'prevents file access' do
        document.quarantine!
        expect(document.safe_to_download?).to be false
      end
    end

    describe '#release_from_quarantine!' do
      before do
        document.quarantine!
      end

      it 'releases document from quarantine' do
        document.release_from_quarantine!
        expect(document.quarantined?).to be false
        expect(document.quarantined_at).to be_nil
      end

      it 'requires clean scan status' do
        document.virus_scan_status = 'infected'
        expect { document.release_from_quarantine! }.to raise_error(RuntimeError, /cannot release infected/)
      end
    end
  end

  describe 'scopes' do
    let!(:clean_doc) { create(:document, virus_scan_status: 'clean') }
    let!(:infected_doc) { create(:document, virus_scan_status: 'infected') }
    let!(:pending_doc) { create(:document, virus_scan_status: 'pending') }
    let!(:quarantined_doc) { create(:document, quarantined: true) }

    describe '.virus_clean' do
      it 'returns only clean documents' do
        expect(Document.virus_clean).to include(clean_doc)
        expect(Document.virus_clean).not_to include(infected_doc, pending_doc)
      end
    end

    describe '.virus_infected' do
      it 'returns only infected documents' do
        expect(Document.virus_infected).to include(infected_doc)
        expect(Document.virus_infected).not_to include(clean_doc, pending_doc)
      end
    end

    describe '.pending_virus_scan' do
      it 'returns documents pending scan' do
        expect(Document.pending_virus_scan).to include(pending_doc)
        expect(Document.pending_virus_scan).not_to include(clean_doc, infected_doc)
      end
    end

    describe '.quarantined' do
      it 'returns quarantined documents' do
        expect(Document.quarantined).to include(quarantined_doc)
        expect(Document.quarantined).not_to include(clean_doc)
      end
    end

    describe '.safe_to_access' do
      it 'returns clean, non-quarantined documents' do
        expect(Document.safe_to_access).to include(clean_doc)
        expect(Document.safe_to_access).not_to include(infected_doc, quarantined_doc)
      end
    end
  end
end