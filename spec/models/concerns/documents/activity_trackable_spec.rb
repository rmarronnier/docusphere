require 'rails_helper'

RSpec.describe Documents::ActivityTrackable do
  let(:document) { create(:document, view_count: 0, download_count: 0) }
  let(:user) { create(:user) }

  describe '#track_view!' do
    it 'increments the view count' do
      expect {
        document.track_view!(user)
      }.to change { document.reload.view_count }.from(0).to(1)
    end
    
    it 'increments view count multiple times' do
      document.track_view!(user)
      document.track_view!(user)
      expect(document.reload.view_count).to eq(2)
    end
  end

  describe '#track_download!' do
    it 'increments the download count' do
      expect {
        document.track_download!(user)
      }.to change { document.reload.download_count }.from(0).to(1)
    end
    
    it 'increments download count multiple times' do
      document.track_download!(user)
      document.track_download!(user)
      expect(document.reload.download_count).to eq(2)
    end
  end
end