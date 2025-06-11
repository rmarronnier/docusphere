require 'rails_helper'

RSpec.describe Documents::DisplayHelpers do
  let(:space) { create(:space, name: 'My Space') }
  let(:parent_folder) { create(:folder, name: 'Parent', space: space) }
  let(:folder) { create(:folder, name: 'Child', parent: parent_folder, space: space) }
  let(:document) { create(:document, title: 'Test Document', space: space, folder: folder) }

  describe '#display_name' do
    it 'returns the document title' do
      expect(document.display_name).to eq('Test Document')
    end
  end

  describe '#full_path' do
    context 'when document has no folder' do
      let(:document) { create(:document, title: 'Root Document', space: space, folder: nil) }
      
      it 'returns path with just the document title' do
        expect(document.full_path).to eq('/Root Document')
      end
    end
    
    context 'when document has a folder' do
      it 'returns full path including folder hierarchy' do
        allow(folder).to receive(:full_path).and_return('/Parent/Child')
        expect(document.full_path).to eq('/Parent/Child/Test Document')
      end
    end
  end

  describe '#breadcrumb_items' do
    context 'when document has no folder' do
      let(:document) { create(:document, title: 'Root Document', space: space, folder: nil) }
      
      it 'returns breadcrumb with space and document' do
        items = document.breadcrumb_items
        
        expect(items.size).to eq(2)
        expect(items[0]).to eq({ name: 'My Space', path: space })
        expect(items[1]).to eq({ name: 'Root Document', path: document })
      end
    end
    
    context 'when document has a folder with ancestors' do
      before do
        allow(folder).to receive(:ancestors).and_return([parent_folder])
      end
      
      it 'returns breadcrumb with full hierarchy' do
        items = document.breadcrumb_items
        
        expect(items.size).to eq(4)
        expect(items[0]).to eq({ name: 'My Space', path: space })
        expect(items[1]).to eq({ name: 'Parent', path: parent_folder })
        expect(items[2]).to eq({ name: 'Child', path: folder })
        expect(items[3]).to eq({ name: 'Test Document', path: document })
      end
    end
  end
end