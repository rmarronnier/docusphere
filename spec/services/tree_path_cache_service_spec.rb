require 'rails_helper'

RSpec.describe TreePathCacheService do
  let(:organization) { create(:organization) }
  let(:space) { create(:space, organization: organization) }
  let(:parent_folder) { create(:folder, parent: space, name: 'Parent Folder') }
  let(:child_folder) { create(:folder, parent: parent_folder, name: 'Child Folder') }
  let(:document) { create(:document, parent: child_folder, name: 'Test Document.pdf') }
  
  describe '.cache_path_for' do
    it 'caches the full path for a document' do
      path = TreePathCacheService.cache_path_for(document)
      
      expect(path).to eq("#{space.name}/Parent Folder/Child Folder/Test Document.pdf")
    end
    
    it 'caches the full path for a folder' do
      path = TreePathCacheService.cache_path_for(child_folder)
      
      expect(path).to eq("#{space.name}/Parent Folder/Child Folder")
    end
    
    it 'stores path in Rails cache' do
      expect(Rails.cache).to receive(:write).with(
        "tree_path:#{document.class.name}:#{document.id}",
        anything,
        expires_in: 1.hour
      )
      
      TreePathCacheService.cache_path_for(document)
    end
    
    it 'returns cached path on subsequent calls' do
      # First call calculates and caches
      TreePathCacheService.cache_path_for(document)
      
      # Second call should use cache
      expect(document).not_to receive(:ancestors)
      cached_path = TreePathCacheService.cache_path_for(document)
      
      expect(cached_path).to eq("#{space.name}/Parent Folder/Child Folder/Test Document.pdf")
    end
  end
  
  describe '.invalidate_path_for' do
    before do
      TreePathCacheService.cache_path_for(document)
      TreePathCacheService.cache_path_for(child_folder)
      TreePathCacheService.cache_path_for(parent_folder)
    end
    
    it 'removes cached path for the item' do
      expect(Rails.cache).to receive(:delete).with(
        "tree_path:#{document.class.name}:#{document.id}"
      )
      
      TreePathCacheService.invalidate_path_for(document)
    end
    
    it 'invalidates paths for all descendants when folder is invalidated' do
      expect(Rails.cache).to receive(:delete).exactly(3).times
      
      TreePathCacheService.invalidate_path_for(parent_folder)
    end
  end
  
  describe '.bulk_cache_paths' do
    let(:items) { [document, child_folder, parent_folder] }
    
    it 'caches paths for multiple items efficiently' do
      paths = TreePathCacheService.bulk_cache_paths(items)
      
      expect(paths).to be_a(Hash)
      expect(paths[document.id]).to eq("#{space.name}/Parent Folder/Child Folder/Test Document.pdf")
      expect(paths[child_folder.id]).to eq("#{space.name}/Parent Folder/Child Folder")
      expect(paths[parent_folder.id]).to eq("#{space.name}/Parent Folder")
    end
    
    it 'minimizes database queries' do
      expect(Folder).to receive(:includes).once.and_call_original
      
      TreePathCacheService.bulk_cache_paths(items)
    end
  end
  
  describe '.update_paths_after_move' do
    let(:new_parent) { create(:folder, parent: space, name: 'New Location') }
    
    it 'updates cached paths after item is moved' do
      # Cache original paths
      TreePathCacheService.cache_path_for(document)
      TreePathCacheService.cache_path_for(child_folder)
      
      # Move the folder
      child_folder.update!(parent: new_parent)
      
      # Update paths
      TreePathCacheService.update_paths_after_move(child_folder, parent_folder)
      
      # Check new paths
      new_path = TreePathCacheService.cache_path_for(child_folder)
      expect(new_path).to eq("#{space.name}/New Location/Child Folder")
      
      # Document path should also be updated
      doc_path = TreePathCacheService.cache_path_for(document)
      expect(doc_path).to eq("#{space.name}/New Location/Child Folder/Test Document.pdf")
    end
  end
  
  describe '.warm_cache_for_space' do
    before do
      create_list(:folder, 3, parent: space)
      create_list(:document, 5, parent: space)
    end
    
    it 'pre-caches all paths in a space' do
      expect(Rails.cache).to receive(:write).at_least(9).times # space + 3 folders + 5 docs
      
      TreePathCacheService.warm_cache_for_space(space)
    end
    
    it 'uses batch processing for performance' do
      expect(TreePathCacheService).to receive(:bulk_cache_paths).at_least(:once)
      
      TreePathCacheService.warm_cache_for_space(space)
    end
  end
  
  describe '.clear_cache_for_organization' do
    it 'clears all cached paths for an organization' do
      TreePathCacheService.cache_path_for(document)
      TreePathCacheService.cache_path_for(child_folder)
      
      expect(Rails.cache).to receive(:delete_matched).with(
        "tree_path:*:org:#{organization.id}:*"
      )
      
      TreePathCacheService.clear_cache_for_organization(organization)
    end
  end
  
  describe 'performance considerations' do
    it 'handles deep nesting efficiently' do
      # Create deep folder structure
      current_parent = space
      10.times do |i|
        current_parent = create(:folder, parent: current_parent, name: "Level #{i}")
      end
      deep_document = create(:document, parent: current_parent, name: 'Deep Document')
      
      start_time = Time.current
      path = TreePathCacheService.cache_path_for(deep_document)
      duration = Time.current - start_time
      
      expect(duration).to be < 0.1 # Should complete in under 100ms
      expect(path.split('/').size).to eq(12) # space + 10 folders + document
    end
    
    it 'uses cache versioning for invalidation' do
      cache_key = TreePathCacheService.send(:cache_key_for, document)
      
      expect(cache_key).to include(TreePathCacheService::CACHE_VERSION)
    end
  end
end