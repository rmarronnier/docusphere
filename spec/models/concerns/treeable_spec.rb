require 'rails_helper'

RSpec.describe Treeable, type: :model do
  # Créons une classe de test pour tester le concern
  let(:test_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'folders'
      include Treeable
      
      def self.name
        'TestTreeable'
      end
    end
  end

  let(:organization) { create(:organization) }
  let(:space) { create(:space, organization: organization) }
  let(:root_folder) { create(:folder, space: space, parent: nil) }
  let(:child_folder) { create(:folder, space: space, parent: root_folder) }
  let(:grandchild_folder) { create(:folder, space: space, parent: child_folder) }

  describe 'associations' do
    it 'includes parent association' do
      expect(root_folder).to respond_to(:parent)
    end

    it 'includes children association' do
      expect(root_folder).to respond_to(:children)
    end
  end

  describe 'scopes' do
    before do
      root_folder
      child_folder
      grandchild_folder
    end

    it 'returns root items' do
      roots = Folder.roots
      expect(roots).to include(root_folder)
      expect(roots).not_to include(child_folder)
      expect(roots).not_to include(grandchild_folder)
    end
  end

  describe '#root?' do
    it 'returns true for root items' do
      expect(root_folder.root?).to be true
    end

    it 'returns false for child items' do
      expect(child_folder.root?).to be false
      expect(grandchild_folder.root?).to be false
    end
  end

  describe '#leaf?' do
    before { grandchild_folder } # Trigger creation

    it 'returns true for items without children' do
      expect(grandchild_folder.leaf?).to be true
    end

    it 'returns false for items with children' do
      expect(root_folder.leaf?).to be false
      expect(child_folder.leaf?).to be false
    end
  end

  describe '#ancestors' do
    before { grandchild_folder } # Trigger creation

    it 'returns empty array for root' do
      expect(root_folder.ancestors).to eq([])
    end

    it 'returns correct ancestors for child' do
      expect(child_folder.ancestors).to eq([root_folder])
    end

    it 'returns correct ancestors for grandchild' do
      expect(grandchild_folder.ancestors).to eq([root_folder, child_folder])
    end
  end

  describe '#root' do
    before { grandchild_folder } # Trigger creation

    it 'returns self for root item' do
      expect(root_folder.root).to eq(root_folder)
    end

    it 'returns root for child items' do
      expect(child_folder.root).to eq(root_folder)
      expect(grandchild_folder.root).to eq(root_folder)
    end
  end

  describe '#descendants' do
    before { grandchild_folder } # Trigger creation

    it 'returns all descendants' do
      descendants = root_folder.descendants
      expect(descendants).to include(child_folder)
      expect(descendants).to include(grandchild_folder)
    end

    it 'returns empty array for leaf items' do
      expect(grandchild_folder.descendants).to eq([])
    end
  end

  describe '#depth' do
    before { grandchild_folder } # Trigger creation

    it 'returns 0 for root' do
      expect(root_folder.depth).to eq(0)
    end

    it 'returns correct depth for children' do
      expect(child_folder.depth).to eq(1)
      expect(grandchild_folder.depth).to eq(2)
    end
  end

  describe '#path' do
    before { grandchild_folder } # Trigger creation

    it 'returns path including self' do
      expect(root_folder.path).to eq([root_folder])
      expect(child_folder.path).to eq([root_folder, child_folder])
      expect(grandchild_folder.path).to eq([root_folder, child_folder, grandchild_folder])
    end
  end

  describe '#path_names' do
    before { grandchild_folder } # Trigger creation

    it 'returns path names joined with /' do
      expect(grandchild_folder.path_names).to eq("#{root_folder.name} / #{child_folder.name} / #{grandchild_folder.name}")
    end
  end

  describe '#can_be_parent_of?' do
    before { grandchild_folder } # Trigger creation

    it 'returns false for self' do
      expect(root_folder.can_be_parent_of?(root_folder)).to be false
    end

    it 'returns false for descendants' do
      expect(root_folder.can_be_parent_of?(child_folder)).to be false
      expect(root_folder.can_be_parent_of?(grandchild_folder)).to be false
    end

    it 'returns true for valid parents' do
      another_folder = create(:folder, space: space, parent: nil)
      expect(another_folder.can_be_parent_of?(root_folder)).to be true
    end
  end

  describe 'validations' do
    it 'prevents circular references' do
      child_folder.parent = grandchild_folder
      expect(child_folder).not_to be_valid
      expect(child_folder.errors[:parent]).to include('cannot be a descendant of itself')
    end

    it 'prevents self as parent' do
      root_folder.parent = root_folder
      expect(root_folder).not_to be_valid
      expect(root_folder.errors[:parent]).to include('cannot be itself')
    end
  end
end