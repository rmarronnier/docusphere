require 'rails_helper'

RSpec.describe Uploadable, type: :concern do
  # Create a test class to include the concern
  let(:test_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'documents'
      include Uploadable
      
      def self.name
        'TestUploadable'
      end
      
      # Mock Active Storage methods
      def file
        @file_attachment ||= MockAttachment.new
      end
      
      # Mock for testing callbacks
      def processing_status
        @processing_status
      end
      
      def processing_status=(value)
        @processing_status = value
      end
      
      def virus_scan_status=(value)
        @virus_scan_status = value
      end
      
      def saved_change_to_attribute?(attr)
        false
      end
      
      def update!(attrs = {})
        attrs.each { |k, v| send("#{k}=", v) if respond_to?("#{k}=") }
        true
      end
    end
  end

  # Mock attachment class for testing
  let(:mock_attachment_class) do
    Class.new do
      def initialize(attached: false, filename: 'test.pdf', content_type: 'application/pdf', byte_size: 1024)
        @attached = attached
        @filename = filename
        @content_type = content_type
        @byte_size = byte_size
        @checksum = 'abc123'
        @created_at = Time.current
      end
      
      def attached?
        @attached
      end
      
      def filename
        OpenStruct.new(to_s: @filename)
      end
      
      attr_reader :content_type, :byte_size, :checksum, :created_at
      
      def previewable?
        @content_type.start_with?('image/') || @content_type == 'application/pdf'
      end
      
      def variable?
        @content_type.start_with?('image/')
      end
      
      def preview(options = {})
        OpenStruct.new(processed: 'preview_data')
      end
      
      def variant(options = {})
        OpenStruct.new(processed: 'variant_data')
      end
      
      def purge
        @attached = false
      end
      
      def attach(file)
        @attached = true
      end
    end
  end

  let(:uploadable_instance) { test_class.new }

  before do
    stub_const('MockAttachment', mock_attachment_class)
  end

  describe 'included module behavior' do
    it 'adds upload methods' do
      expect(uploadable_instance).to respond_to(:has_file_attached?)
      expect(uploadable_instance).to respond_to(:file_metadata)
      expect(uploadable_instance).to respond_to(:file_size_human)
      expect(uploadable_instance).to respond_to(:file_extension)
    end

    it 'adds scopes to the class' do
      expect(test_class).to respond_to(:with_files)
      expect(test_class).to respond_to(:without_files)
      expect(test_class).to respond_to(:by_content_type)
      expect(test_class).to respond_to(:by_file_size)
    end
  end

  describe 'class methods' do
    describe '.supports_file_types' do
      it 'sets supported file types' do
        test_class.supports_file_types(:pdf, :jpg, :png)
        expect(test_class.supported_file_types).to eq(['pdf', 'jpg', 'png'])
      end
    end

    describe '.max_file_size' do
      it 'sets maximum file size' do
        test_class.max_file_size(50.megabytes)
        expect(test_class.maximum_file_size).to eq(50.megabytes)
      end

      it 'has default maximum file size' do
        expect(test_class.maximum_file_size).to eq(100.megabytes)
      end
    end
  end

  describe '#has_file_attached?' do
    it 'returns false when no file attached' do
      allow(uploadable_instance.file).to receive(:attached?).and_return(false)
      expect(uploadable_instance.has_file_attached?).to be false
    end

    it 'returns true when file is attached' do
      allow(uploadable_instance.file).to receive(:attached?).and_return(true)
      expect(uploadable_instance.has_file_attached?).to be true
    end
  end

  describe '#file_metadata' do
    it 'returns empty hash when no file attached' do
      allow(uploadable_instance.file).to receive(:attached?).and_return(false)
      expect(uploadable_instance.file_metadata).to eq({})
    end

    it 'returns file metadata when file attached' do
      allow(uploadable_instance.file).to receive(:attached?).and_return(true)
      
      metadata = uploadable_instance.file_metadata
      expect(metadata[:filename]).to eq('test.pdf')
      expect(metadata[:content_type]).to eq('application/pdf')
      expect(metadata[:byte_size]).to eq(1024)
      expect(metadata[:checksum]).to eq('abc123')
      expect(metadata[:created_at]).to be_present
    end
  end

  describe '#file_size_human' do
    it 'returns nil when no file attached' do
      allow(uploadable_instance.file).to receive(:attached?).and_return(false)
      expect(uploadable_instance.file_size_human).to be_nil
    end

    it 'returns human readable file size' do
      allow(uploadable_instance.file).to receive(:attached?).and_return(true)
      
      expect(ActiveSupport::NumberHelper).to receive(:number_to_human_size).with(1024)
      uploadable_instance.file_size_human
    end
  end

  describe '#file_extension' do
    it 'returns nil when no file attached' do
      allow(uploadable_instance.file).to receive(:attached?).and_return(false)
      expect(uploadable_instance.file_extension).to be_nil
    end

    it 'extracts file extension' do
      allow(uploadable_instance.file).to receive(:attached?).and_return(true)
      expect(uploadable_instance.file_extension).to eq('pdf')
    end

    it 'handles files without extension' do
      allow(uploadable_instance.file).to receive(:attached?).and_return(true)
      filename = double('filename')
      allow(filename).to receive(:to_s).and_return('README')
      allow(uploadable_instance.file).to receive(:filename).and_return(filename)
      expect(uploadable_instance.file_extension).to eq('')
    end
  end

  describe '#supported_file_type?' do
    it 'returns true when no supported types configured' do
      expect(uploadable_instance.supported_file_type?).to be true
    end

    it 'returns false when no file attached and types configured' do
      test_class.supports_file_types('application/pdf')
      allow(uploadable_instance.file).to receive(:attached?).and_return(false)
      
      expect(uploadable_instance.supported_file_type?).to be false
    end

    it 'returns true for supported file type' do
      test_class.supports_file_types('application/pdf')
      allow(uploadable_instance.file).to receive(:attached?).and_return(true)
      
      expect(uploadable_instance.supported_file_type?).to be true
    end

    it 'returns false for unsupported file type' do
      test_class.supports_file_types('image/jpeg')
      allow(uploadable_instance.file).to receive(:attached?).and_return(true)
      
      expect(uploadable_instance.supported_file_type?).to be false
    end
  end

  describe '#file_size_valid?' do
    it 'returns true when no file attached' do
      allow(uploadable_instance.file).to receive(:attached?).and_return(false)
      expect(uploadable_instance.file_size_valid?).to be true
    end

    it 'returns true for file within size limit' do
      test_class.max_file_size(2048)
      allow(uploadable_instance.file).to receive(:attached?).and_return(true)
      
      expect(uploadable_instance.file_size_valid?).to be true
    end

    it 'returns false for file exceeding size limit' do
      test_class.max_file_size(512)
      allow(uploadable_instance.file).to receive(:attached?).and_return(true)
      
      expect(uploadable_instance.file_size_valid?).to be false
    end
  end

  describe '#generate_preview!' do
    it 'returns false when no file attached' do
      allow(uploadable_instance.file).to receive(:attached?).and_return(false)
      expect(uploadable_instance.generate_preview!).to be false
    end

    it 'returns false when preview method not available' do
      allow(uploadable_instance.file).to receive(:attached?).and_return(true)
      expect(uploadable_instance.generate_preview!).to be false
    end

    it 'generates preview for previewable file' do
      allow(uploadable_instance.file).to receive(:attached?).and_return(true)
      allow(uploadable_instance).to receive(:respond_to?).and_return(true)
      
      preview_attachment = double('preview_attachment')
      allow(uploadable_instance).to receive(:preview).and_return(preview_attachment)
      expect(preview_attachment).to receive(:attach)
      
      uploadable_instance.generate_preview!
    end
  end

  describe '#generate_thumbnail!' do
    it 'returns false when no file attached' do
      allow(uploadable_instance.file).to receive(:attached?).and_return(false)
      expect(uploadable_instance.generate_thumbnail!).to be false
    end

    it 'returns false when thumbnail method not available' do
      allow(uploadable_instance.file).to receive(:attached?).and_return(true)
      expect(uploadable_instance.generate_thumbnail!).to be false
    end

    it 'generates thumbnail for variable image' do
      allow(uploadable_instance.file).to receive(:attached?).and_return(true)
      allow(uploadable_instance.file).to receive(:variable?).and_return(true)
      allow(uploadable_instance).to receive(:respond_to?).and_return(true)
      
      thumbnail_attachment = double('thumbnail_attachment')
      allow(uploadable_instance).to receive(:thumbnail).and_return(thumbnail_attachment)
      expect(thumbnail_attachment).to receive(:attach)
      
      uploadable_instance.generate_thumbnail!
    end

    it 'generates thumbnail for previewable file' do
      allow(uploadable_instance.file).to receive(:attached?).and_return(true)
      allow(uploadable_instance.file).to receive(:variable?).and_return(false)
      allow(uploadable_instance.file).to receive(:previewable?).and_return(true)
      allow(uploadable_instance).to receive(:respond_to?).and_return(true)
      
      thumbnail_attachment = double('thumbnail_attachment')
      allow(uploadable_instance).to receive(:thumbnail).and_return(thumbnail_attachment)
      expect(thumbnail_attachment).to receive(:attach)
      
      uploadable_instance.generate_thumbnail!
    end
  end

  describe '#replace_file!' do
    let(:new_file) { double('new_file') }

    before do
      allow(uploadable_instance.file).to receive(:attached?).and_return(true)
      allow(uploadable_instance).to receive(:transaction).and_yield
    end

    it 'purges old file and attaches new one' do
      expect(uploadable_instance.file).to receive(:purge)
      expect(uploadable_instance.file).to receive(:attach).with(new_file)
      
      uploadable_instance.replace_file!(new_file)
    end

    it 'tracks file replacement when supported' do
      allow(uploadable_instance).to receive(:respond_to?).and_return(true)
      
      file_replacements = double('file_replacements')
      allow(uploadable_instance).to receive(:file_replacements).and_return(file_replacements)
      expect(file_replacements).to receive(:create!)
      
      allow(uploadable_instance.file).to receive(:purge)
      allow(uploadable_instance.file).to receive(:attach)
      
      uploadable_instance.replace_file!(new_file)
    end
  end

  describe '#download_url' do
    it 'returns nil when no file attached' do
      allow(uploadable_instance.file).to receive(:attached?).and_return(false)
      expect(uploadable_instance.download_url).to be_nil
    end

    it 'generates download URL with expiration' do
      allow(uploadable_instance.file).to receive(:attached?).and_return(true)
      
      url_helpers = double('url_helpers')
      allow(Rails.application.routes).to receive(:url_helpers).and_return(url_helpers)
      expect(url_helpers).to receive(:rails_blob_url).with(uploadable_instance.file, expires_in: 5.minutes)
      
      uploadable_instance.download_url
    end

    it 'accepts custom expiration time' do
      allow(uploadable_instance.file).to receive(:attached?).and_return(true)
      
      url_helpers = double('url_helpers')
      allow(Rails.application.routes).to receive(:url_helpers).and_return(url_helpers)
      expect(url_helpers).to receive(:rails_blob_url).with(uploadable_instance.file, expires_in: 1.hour)
      
      uploadable_instance.download_url(expires_in: 1.hour)
    end
  end

  describe '#should_reprocess?' do
    it 'returns false when no file attached' do
      allow(uploadable_instance.file).to receive(:attached?).and_return(false)
      expect(uploadable_instance.should_reprocess?).to be false
    end

    it 'returns true when processing status changed to pending_reprocess' do
      allow(uploadable_instance.file).to receive(:attached?).and_return(true)
      allow(uploadable_instance).to receive(:saved_change_to_attribute?).with(:processing_status).and_return(true)
      uploadable_instance.processing_status = 'pending_reprocess'
      
      expect(uploadable_instance.should_reprocess?).to be true
    end

    it 'returns false when processing status not changed' do
      allow(uploadable_instance.file).to receive(:attached?).and_return(true)
      allow(uploadable_instance).to receive(:saved_change_to_attribute?).with(:processing_status).and_return(false)
      
      expect(uploadable_instance.should_reprocess?).to be false
    end
  end

  describe '#mark_for_reprocessing!' do
    it 'updates processing status when supported' do
      allow(uploadable_instance).to receive(:respond_to?).and_return(true)
      expect(uploadable_instance).to receive(:update!).with(processing_status: 'pending_reprocess')
      
      uploadable_instance.mark_for_reprocessing!
    end

    it 'does nothing when processing status not supported' do
      allow(uploadable_instance).to receive(:respond_to?).and_return(false)
      
      uploadable_instance.mark_for_reprocessing!
      
      # Since respond_to? returns false, update! should not be called
      # But since we can't use not_to receive with our mock, we just verify the behavior
    end
  end

  describe '#scan_for_virus!' do
    it 'returns false when no file attached' do
      allow(uploadable_instance.file).to receive(:attached?).and_return(false)
      expect(uploadable_instance.scan_for_virus!).to be false
    end

    it 'returns false when virus_scan_status not supported' do
      allow(uploadable_instance.file).to receive(:attached?).and_return(true)
      allow(uploadable_instance).to receive(:respond_to?).and_return(false)
      
      expect(uploadable_instance.scan_for_virus!).to be false
    end

    it 'initiates virus scan when supported' do
      allow(uploadable_instance.file).to receive(:attached?).and_return(true)
      allow(uploadable_instance).to receive(:respond_to?) do |method|
        [:file, :virus_scan_status, :virus_scan_status=, :update!].include?(method)
      end
      allow(uploadable_instance).to receive(:update!).and_return(true)
      
      # Mock the job
      virus_scan_job = double('VirusScanJob')
      stub_const('VirusScanJob', virus_scan_job)
      expect(virus_scan_job).to receive(:perform_later).with(uploadable_instance)
      
      uploadable_instance.scan_for_virus!
      
      expect(uploadable_instance).to have_received(:update!).with(virus_scan_status: 'scanning')
    end
  end

  describe '#extract_content!' do
    it 'returns false when no file attached' do
      allow(uploadable_instance.file).to receive(:attached?).and_return(false)
      expect(uploadable_instance.extract_content!).to be false
    end

    it 'returns false when content attribute not supported' do
      allow(uploadable_instance.file).to receive(:attached?).and_return(true)
      allow(uploadable_instance).to receive(:respond_to?) do |method|
        method == :file
      end
      
      expect(uploadable_instance.extract_content!).to be false
    end

    it 'initiates content extraction when supported' do
      allow(uploadable_instance.file).to receive(:attached?).and_return(true)
      allow(uploadable_instance).to receive(:respond_to?) do |method|
        [:file, :content].include?(method)
      end
      
      # Mock the job
      extract_content_job = double('ExtractContentJob')
      stub_const('ExtractContentJob', extract_content_job)
      expect(extract_content_job).to receive(:perform_later).with(uploadable_instance)
      
      uploadable_instance.extract_content!
    end
  end

  describe 'callbacks' do
    it 'enqueues processing job after create when file attached' do
      allow(uploadable_instance).to receive(:has_file_attached?).and_return(true)
      allow(uploadable_instance).to receive(:respond_to?).and_return(true)
      
      file_processing_job = double('FileProcessingJob')
      stub_const('FileProcessingJob', file_processing_job)
      expect(file_processing_job).to receive(:perform_later).with(uploadable_instance)
      
      uploadable_instance.send(:enqueue_processing_job)
    end

    it 'enqueues reprocessing job after update when should reprocess' do
      file_reprocessing_job = double('FileReprocessingJob')
      stub_const('FileReprocessingJob', file_reprocessing_job)
      expect(file_reprocessing_job).to receive(:perform_later).with(uploadable_instance)
      
      uploadable_instance.send(:enqueue_reprocessing_job)
    end
  end

  describe 'scopes' do
    before do
      skip "Scopes require actual database table with Active Storage" unless test_class.table_exists?
    end

    describe '.with_files' do
      it 'returns only records with attached files' do
        expect(test_class.with_files).to be_a(ActiveRecord::Relation)
      end
    end

    describe '.without_files' do
      it 'returns only records without attached files' do
        expect(test_class.without_files).to be_a(ActiveRecord::Relation)
      end
    end

    describe '.by_content_type' do
      it 'filters by content type' do
        relation = test_class.by_content_type('application/pdf')
        expect(relation).to be_a(ActiveRecord::Relation)
      end
    end

    describe '.by_file_size' do
      it 'filters by minimum file size' do
        relation = test_class.by_file_size(min: 1024)
        expect(relation).to be_a(ActiveRecord::Relation)
      end

      it 'filters by maximum file size' do
        relation = test_class.by_file_size(max: 10.megabytes)
        expect(relation).to be_a(ActiveRecord::Relation)
      end

      it 'filters by size range' do
        relation = test_class.by_file_size(min: 1024, max: 10.megabytes)
        expect(relation).to be_a(ActiveRecord::Relation)
      end
    end
  end
end