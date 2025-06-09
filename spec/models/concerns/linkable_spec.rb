require 'rails_helper'

RSpec.describe Linkable, type: :concern do
  # Create test classes to include the concern
  let(:test_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'documents'
      include Linkable
      
      def self.name
        'TestLinkable'
      end
    end
  end

  let(:other_test_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'folders'
      include Linkable
      
      def self.name
        'OtherTestLinkable'
      end
    end
  end

  let(:organization) { create(:organization) }
  let(:space) { create(:space, organization: organization) }
  let(:linkable_source) { create(:document, space: space) }
  let(:linkable_target) { create(:document, space: space) }
  let(:linkable_other) { create(:folder, space: space) }

  describe 'included module behavior' do
    it 'adds link associations' do
      expect(linkable_source).to respond_to(:source_links)
      expect(linkable_source).to respond_to(:target_links)
    end

    it 'adds linking methods' do
      expect(linkable_source).to respond_to(:link_to)
      expect(linkable_source).to respond_to(:link_with)
      expect(linkable_source).to respond_to(:unlink_from)
      expect(linkable_source).to respond_to(:unlink_with)
      expect(linkable_source).to respond_to(:linked_to?)
      expect(linkable_source).to respond_to(:linked_from?)
    end

    it 'adds scopes to the class' do
      expect(Document).to respond_to(:linked_to)
      expect(Document).to respond_to(:linked_from)
      expect(Document).to respond_to(:with_link_type)
    end
  end

  describe '#link_to' do
    it 'creates a link to another object' do
      expect {
        linkable_source.link_to(linkable_target)
      }.to change { linkable_source.source_links.count }.by(1)
      
      link = linkable_source.source_links.last
      expect(link.target).to eq(linkable_target)
      expect(link.link_type).to eq('related')
    end

    it 'accepts custom link type' do
      linkable_source.link_to(linkable_target, link_type: 'reference')
      
      link = linkable_source.source_links.last
      expect(link.link_type).to eq('reference')
    end

    it 'accepts metadata' do
      metadata = { description: 'Test link', weight: 1.5 }
      linkable_source.link_to(linkable_target, metadata: metadata)
      
      link = linkable_source.source_links.last
      expect(link.metadata).to eq(metadata.stringify_keys)
    end

    it 'prevents linking to self' do
      result = linkable_source.link_to(linkable_source)
      expect(result).to be false
      expect(linkable_source.source_links).to be_empty
    end

    it 'prevents duplicate links' do
      linkable_source.link_to(linkable_target, link_type: 'reference')
      result = linkable_source.link_to(linkable_target, link_type: 'reference')
      
      expect(result).to be false
      expect(linkable_source.source_links.count).to eq(1)
    end

    it 'allows same target with different link type' do
      linkable_source.link_to(linkable_target, link_type: 'reference')
      linkable_source.link_to(linkable_target, link_type: 'related')
      
      expect(linkable_source.source_links.count).to eq(2)
    end
  end

  describe '#link_with' do
    it 'creates bidirectional links' do
      linkable_source.link_with(linkable_target)
      
      expect(linkable_source.linked_to?(linkable_target)).to be true
      expect(linkable_target.linked_to?(linkable_source)).to be true
    end

    it 'prevents linking with self' do
      result = linkable_source.link_with(linkable_source)
      expect(result).to be false
    end

    it 'is transactional' do
      # Simulate failure in the second link creation
      allow(linkable_target).to receive(:link_to).and_raise(ActiveRecord::RecordInvalid)
      
      expect {
        linkable_source.link_with(linkable_target)
      }.to raise_error(ActiveRecord::RecordInvalid)
      
      expect(linkable_source.reload.source_links).to be_empty
    end
  end

  describe '#unlink_from' do
    before do
      linkable_source.link_to(linkable_target, link_type: 'reference')
      linkable_source.link_to(linkable_target, link_type: 'related')
    end

    it 'removes specific link type' do
      linkable_source.unlink_from(linkable_target, link_type: 'reference')
      
      expect(linkable_source.linked_to?(linkable_target, link_type: 'reference')).to be false
      expect(linkable_source.linked_to?(linkable_target, link_type: 'related')).to be true
    end

    it 'removes all links when no type specified' do
      linkable_source.unlink_from(linkable_target)
      
      expect(linkable_source.linked_to?(linkable_target)).to be false
      expect(linkable_source.source_links.where(target: linkable_target)).to be_empty
    end
  end

  describe '#unlink_with' do
    before do
      linkable_source.link_with(linkable_target)
    end

    it 'removes bidirectional links' do
      linkable_source.unlink_with(linkable_target)
      
      expect(linkable_source.linked_to?(linkable_target)).to be false
      expect(linkable_target.linked_to?(linkable_source)).to be false
    end
  end

  describe '#linked_to?' do
    before do
      linkable_source.link_to(linkable_target, link_type: 'reference')
    end

    it 'returns true when linked' do
      expect(linkable_source.linked_to?(linkable_target)).to be true
    end

    it 'returns false when not linked' do
      expect(linkable_target.linked_to?(linkable_source)).to be false
    end

    it 'checks specific link type' do
      expect(linkable_source.linked_to?(linkable_target, link_type: 'reference')).to be true
      expect(linkable_source.linked_to?(linkable_target, link_type: 'related')).to be false
    end
  end

  describe '#linked_from?' do
    before do
      linkable_source.link_to(linkable_target, link_type: 'reference')
    end

    it 'returns true when linked from' do
      expect(linkable_target.linked_from?(linkable_source)).to be true
    end

    it 'returns false when not linked from' do
      expect(linkable_source.linked_from?(linkable_target)).to be false
    end

    it 'checks specific link type' do
      expect(linkable_target.linked_from?(linkable_source, link_type: 'reference')).to be true
      expect(linkable_target.linked_from?(linkable_source, link_type: 'related')).to be false
    end
  end

  describe '#linked_with?' do
    it 'returns true when bidirectionally linked' do
      linkable_source.link_with(linkable_target)
      expect(linkable_source.linked_with?(linkable_target)).to be true
    end

    it 'returns false when only unidirectionally linked' do
      linkable_source.link_to(linkable_target)
      expect(linkable_source.linked_with?(linkable_target)).to be false
    end
  end

  describe '#linked_targets' do
    before do
      linkable_source.link_to(linkable_target, link_type: 'reference')
      linkable_source.link_to(linkable_other, link_type: 'related')
    end

    it 'returns all linked targets' do
      targets = linkable_source.linked_targets
      expect(targets).to include(linkable_target, linkable_other)
    end

    it 'filters by link type' do
      targets = linkable_source.linked_targets(link_type: 'reference')
      expect(targets).to include(linkable_target)
      expect(targets).not_to include(linkable_other)
    end
  end

  describe '#linked_sources' do
    before do
      linkable_source.link_to(linkable_target, link_type: 'reference')
      linkable_other.link_to(linkable_target, link_type: 'related')
    end

    it 'returns all linked sources' do
      sources = linkable_target.linked_sources
      expect(sources).to include(linkable_source, linkable_other)
    end

    it 'filters by link type' do
      sources = linkable_target.linked_sources(link_type: 'reference')
      expect(sources).to include(linkable_source)
      expect(sources).not_to include(linkable_other)
    end
  end

  describe '#all_linked_objects' do
    before do
      linkable_source.link_to(linkable_target)
      linkable_other.link_to(linkable_source)
    end

    it 'returns objects linked in both directions' do
      linked = linkable_source.all_linked_objects
      expect(linked).to include(linkable_target, linkable_other)
    end

    it 'returns unique objects' do
      linkable_source.link_with(linkable_target) # Creates bidirectional link
      linked = linkable_source.all_linked_objects
      expect(linked.count(linkable_target)).to eq(1)
    end
  end

  describe '#links_by_type' do
    before do
      linkable_source.link_to(linkable_target, link_type: 'reference')
      linkable_source.link_to(linkable_other, link_type: 'reference')
      linkable_other.link_to(linkable_source, link_type: 'related')
    end

    it 'groups links by type' do
      links_by_type = linkable_source.links_by_type
      expect(links_by_type['reference'].size).to eq(2)
      expect(links_by_type['related'].size).to eq(1)
    end
  end

  describe 'convenience methods' do
    before do
      linkable_source.link_to(linkable_target, link_type: 'related')
      linkable_source.link_to(linkable_other, link_type: 'child')
      linkable_target.link_to(linkable_source, link_type: 'child')
      linkable_source.link_to(linkable_target, link_type: 'reference')
    end

    describe '#related_objects' do
      it 'returns objects with related link type' do
        expect(linkable_source.related_objects).to include(linkable_target)
        expect(linkable_source.related_objects).not_to include(linkable_other)
      end
    end

    describe '#child_objects' do
      it 'returns objects with child link type' do
        expect(linkable_source.child_objects).to include(linkable_other)
        expect(linkable_source.child_objects).not_to include(linkable_target)
      end
    end

    describe '#parent_objects' do
      it 'returns objects that link to this with child type' do
        expect(linkable_source.parent_objects).to include(linkable_target)
      end
    end

    describe '#referenced_objects' do
      it 'returns objects with reference link type' do
        expect(linkable_source.referenced_objects).to include(linkable_target)
      end
    end

    describe '#referencing_objects' do
      it 'returns objects that reference this' do
        linkable_other.link_to(linkable_source, link_type: 'reference')
        expect(linkable_source.referencing_objects).to include(linkable_other)
      end
    end
  end

  describe 'parent-child relationship methods' do
    describe '#add_child' do
      it 'creates child relationship' do
        linkable_source.add_child(linkable_target)
        expect(linkable_source.child_objects).to include(linkable_target)
      end
    end

    describe '#set_parent' do
      it 'creates parent relationship' do
        linkable_source.set_parent(linkable_target)
        expect(linkable_source.parent_objects).to include(linkable_target)
      end
    end

    describe '#add_reference' do
      it 'creates reference relationship' do
        linkable_source.add_reference(linkable_target)
        expect(linkable_source.referenced_objects).to include(linkable_target)
      end
    end
  end

  describe '#link_to_target and #link_from_source' do
    before do
      linkable_source.link_to(linkable_target, link_type: 'reference')
    end

    it 'finds specific link to target' do
      link = linkable_source.link_to_target(linkable_target)
      expect(link).to be_present
      expect(link.target).to eq(linkable_target)
    end

    it 'finds specific link from source' do
      link = linkable_target.link_from_source(linkable_source)
      expect(link).to be_present
      expect(link.source).to eq(linkable_source)
    end
  end

  describe '#update_link_metadata' do
    before do
      linkable_source.link_to(linkable_target, metadata: { original: 'data' })
    end

    it 'updates link metadata' do
      new_metadata = { updated: 'value' }
      linkable_source.update_link_metadata(linkable_target, new_metadata)
      
      link = linkable_source.link_to_target(linkable_target)
      expect(link.metadata['original']).to eq('data')
      expect(link.metadata['updated']).to eq('value')
    end

    it 'returns false if link not found' do
      result = linkable_source.update_link_metadata(linkable_other, {})
      expect(result).to be false
    end
  end

  describe '#link_chain' do
    let(:linkable_third) { create(:document, space: space) }
    let(:linkable_fourth) { create(:document, space: space) }

    before do
      linkable_source.link_to(linkable_target, link_type: 'chain')
      linkable_target.link_to(linkable_third, link_type: 'chain')
      linkable_third.link_to(linkable_fourth, link_type: 'chain')
    end

    it 'follows link chain forward' do
      chain = linkable_source.link_chain(link_type: 'chain')
      expect(chain).to eq([linkable_source, linkable_target, linkable_third, linkable_fourth])
    end

    it 'follows link chain backward' do
      chain = linkable_fourth.link_chain(link_type: 'chain', direction: :backward)
      expect(chain).to eq([linkable_fourth, linkable_third, linkable_target, linkable_source])
    end

    it 'respects max depth' do
      chain = linkable_source.link_chain(link_type: 'chain', max_depth: 2)
      expect(chain).to eq([linkable_source, linkable_target, linkable_third])
    end

    it 'handles circular references' do
      linkable_fourth.link_to(linkable_source, link_type: 'chain')
      chain = linkable_source.link_chain(link_type: 'chain')
      expect(chain.length).to be <= 10 # Should not be infinite
    end
  end

  describe '#shortest_path_to' do
    let(:linkable_third) { create(:document, space: space) }

    before do
      linkable_source.link_to(linkable_target)
      linkable_target.link_to(linkable_third)
      linkable_source.link_to(linkable_third) # Direct path
    end

    it 'finds shortest path between objects' do
      path = linkable_source.shortest_path_to(linkable_third)
      expect(path).to eq([linkable_source, linkable_third]) # Direct path
    end

    it 'returns empty array when target is same as source' do
      path = linkable_source.shortest_path_to(linkable_source)
      expect(path).to eq([])
    end

    it 'returns empty array when no path exists' do
      isolated_doc = create(:document, space: space)
      path = linkable_source.shortest_path_to(isolated_doc)
      expect(path).to eq([])
    end
  end

  describe '#link_stats' do
    before do
      linkable_source.link_to(linkable_target, link_type: 'reference')
      linkable_source.link_to(linkable_other, link_type: 'related')
      linkable_target.link_to(linkable_source, link_type: 'reference')
    end

    it 'returns comprehensive link statistics' do
      stats = linkable_source.link_stats
      
      expect(stats[:total_links]).to eq(3)
      expect(stats[:outgoing_links]).to eq(2)
      expect(stats[:incoming_links]).to eq(1)
      expect(stats[:link_types]['reference']).to eq(2)
      expect(stats[:link_types]['related']).to eq(1)
      expect(stats[:unique_linked_objects]).to eq(2)
    end
  end

  describe 'scopes' do
    before do
      linkable_source.link_to(linkable_target)
      linkable_other.link_to(linkable_target)
    end

    describe '.linked_to' do
      it 'finds objects linked to target' do
        linked = Document.linked_to(linkable_target)
        expect(linked).to include(linkable_source)
      end
    end

    describe '.linked_from' do
      it 'finds objects linked from source' do
        linked = Document.linked_from(linkable_source)
        expect(linked).to include(linkable_target)
      end
    end
  end
end