require 'rails_helper'

RSpec.describe Storable, type: :concern do
  include ActiveSupport::Testing::TimeHelpers
  # Create a test class to include the concern
  # We need to define this as a constant for ActiveStorage to work properly
  class ::TestStorable < ActiveRecord::Base
    self.table_name = 'documents'
    include Storable
    
    belongs_to :uploaded_by, class_name: 'User'
    has_one_attached :file
    
    def name
      'Test Document'
    end
  end
  
  let(:test_class) { TestStorable }

  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:space) { create(:space, organization: organization, name: 'Test Space') }
  let(:parent_folder) { create(:folder, space: space, name: 'Parent Folder') }
  let(:child_folder) { create(:folder, space: space, parent: parent_folder, name: 'Child Folder') }
  let(:storable_instance) do
    instance = test_class.new
    instance.title = 'Test Document'
    instance.uploaded_by = user
    instance.space = space
    instance.file.attach(
      io: StringIO.new('test content'),
      filename: 'test.txt',
      content_type: 'text/plain'
    )
    instance
  end

  describe 'included module behavior' do
    it 'adds space and folder associations' do
      expect(storable_instance).to respond_to(:space)
      expect(storable_instance).to respond_to(:folder)
    end

    it 'adds storage methods' do
      expect(storable_instance).to respond_to(:storage_path)
      expect(storable_instance).to respond_to(:storage_parent)
      expect(storable_instance).to respond_to(:move_to)
      expect(storable_instance).to respond_to(:copy_to)
    end

    it 'validates space presence unless orphaned storage allowed' do
      storable_instance.space = nil
      storable_instance.folder = nil
      
      expect(storable_instance).not_to be_valid
      expect(storable_instance.errors[:space]).to include("can't be blank").or(include("ne peut pas être vide"))
    end

    it 'validates folder belongs to space' do
      other_space = create(:space, organization: organization)
      other_folder = create(:folder, space: other_space)
      
      storable_instance.space = space
      storable_instance.folder = other_folder
      
      expect(storable_instance).not_to be_valid
      expect(storable_instance.errors[:folder]).to include('must belong to the same space')
    end

    it 'adds scopes to the class' do
      expect(test_class).to respond_to(:in_space)
      expect(test_class).to respond_to(:in_folder)
      expect(test_class).to respond_to(:root_items)
      expect(test_class).to respond_to(:by_path)
      expect(test_class).to respond_to(:orphaned)
    end
  end

  describe 'class methods' do
    before do
      skip "Tests require documents table" unless test_class.table_exists?
    end

    describe '.find_by_path' do
      it 'finds record by storage path' do
        item = test_class.new(space: space, uploaded_by: user, title: 'Test Doc')
        item.file.attach(io: StringIO.new('test'), filename: 'test.txt', content_type: 'text/plain')
        item.save!
        # Storage path will be updated on save
        
        found = test_class.find_by_path(item.storage_path)
        expect(found).to eq(item)
      end
    end

    describe '.within_path' do
      it 'finds records within a path' do
        item = test_class.new(space: space, folder: child_folder, uploaded_by: user, title: 'Test Doc')
        item.file.attach(io: StringIO.new('test'), filename: 'test.txt', content_type: 'text/plain')
        item.save!
        
        results = test_class.within_path('/test-space')
        expect(results).to include(item)
      end
    end

    describe '.allow_orphaned_storage' do
      it 'configures orphaned storage setting' do
        test_class.allow_orphaned_storage(true)
        expect(test_class.orphaned_storage_allowed?).to be true
        
        test_class.allow_orphaned_storage(false)
        expect(test_class.orphaned_storage_allowed?).to be false
      end
    end
  end

  describe '#storage_path' do
    it 'returns root path when no space' do
      storable_instance.space = nil
      expect(storable_instance.storage_path).to eq('/')
    end

    it 'includes space in path' do
      storable_instance.space = space
      expect(storable_instance.storage_path).to include('test-space')
    end

    it 'includes folder hierarchy in path' do
      storable_instance.space = space
      storable_instance.folder = child_folder
      
      path = storable_instance.storage_path
      expect(path).to include('test-space')
      expect(path).to include('parent-folder')
      expect(path).to include('child-folder')
      expect(path).to include('test-document')
    end

    it 'uses slug when available' do
      space.update!(slug: 'custom-slug')
      storable_instance.space = space
      
      expect(storable_instance.storage_path).to include('custom-slug')
    end
  end

  describe '#storage_parent' do
    it 'returns folder when present' do
      storable_instance.folder = child_folder
      storable_instance.space = space
      
      expect(storable_instance.storage_parent).to eq(child_folder)
    end

    it 'returns space when no folder' do
      storable_instance.space = space
      
      expect(storable_instance.storage_parent).to eq(space)
    end
  end

  describe '#move_to' do
    before do
      storable_instance.space = space
      storable_instance.save! if storable_instance.respond_to?(:save!)
    end

    it 'moves to different space' do
      other_space = create(:space, organization: organization)
      storable_instance.move_to(other_space)
      
      expect(storable_instance.space).to eq(other_space)
      expect(storable_instance.folder).to be_nil
    end

    it 'moves to different folder' do
      storable_instance.move_to(child_folder)
      
      expect(storable_instance.space).to eq(child_folder.space)
      expect(storable_instance.folder).to eq(child_folder)
    end

    it 'moves to root when destination is nil' do
      storable_instance.folder = child_folder
      storable_instance.move_to(nil)
      
      expect(storable_instance.folder).to be_nil
    end

    it 'raises error for invalid destination' do
      expect {
        storable_instance.move_to('invalid')
      }.to raise_error(ArgumentError, /Invalid destination type/)
    end
  end

  describe '#copy_to' do
    before do
      storable_instance.space = space
      storable_instance.save! if storable_instance.respond_to?(:save!)
    end

    it 'creates copy in different space' do
      other_space = create(:space, organization: organization)
      copy = storable_instance.copy_to(other_space)
      
      expect(copy).to be_a(test_class)
      expect(copy.space).to eq(other_space)
      expect(copy.id).not_to eq(storable_instance.id)
    end

    it 'creates copy in different folder' do
      copy = storable_instance.copy_to(child_folder)
      
      expect(copy.space).to eq(child_folder.space)
      expect(copy.folder).to eq(child_folder)
    end

    it 'raises error for invalid destination' do
      expect {
        storable_instance.copy_to('invalid')
      }.to raise_error(ArgumentError, /Invalid destination type/)
    end
  end

  describe '#storage_size' do
    it 'returns 0 when no file attached' do
      instance_without_file = test_class.new
      instance_without_file.title = 'Test Document'
      instance_without_file.uploaded_by = user
      instance_without_file.space = space
      expect(instance_without_file.storage_size).to eq(0)
    end

    it 'returns file size when file attached' do
      if storable_instance.respond_to?(:file)
        # Mock file attachment
        file_double = double('file', attached?: true, byte_size: 1024)
        allow(storable_instance).to receive(:file).and_return(file_double)
        
        expect(storable_instance.storage_size).to eq(1024)
      end
    end
  end

  describe '#total_storage_size' do
    it 'returns storage size for leaf items' do
      expect(storable_instance.total_storage_size).to eq(storable_instance.storage_size)
    end

    it 'includes children sizes when applicable' do
      if storable_instance.respond_to?(:children)
        child1 = double('child1', total_storage_size: 100)
        child2 = double('child2', total_storage_size: 200)
        allow(storable_instance).to receive(:children).and_return([child1, child2])
        allow(storable_instance).to receive(:storage_size).and_return(50)
        
        expect(storable_instance.total_storage_size).to eq(350)
      end
    end
  end

  describe '#can_be_moved_by?' do
    let(:user) { create(:user, organization: organization) }

    it 'returns false for nil user' do
      expect(storable_instance.can_be_moved_by?(nil)).to be false
    end

    it 'checks write permissions on object' do
      if storable_instance.respond_to?(:writable_by?)
        allow(storable_instance).to receive(:writable_by?).with(user).and_return(false)
        expect(storable_instance.can_be_moved_by?(user)).to be false
      end
    end

    it 'checks write permissions on parent folder' do
      storable_instance.folder = child_folder
      
      if child_folder.respond_to?(:writable_by?)
        allow(child_folder).to receive(:writable_by?).with(user).and_return(false)
        expect(storable_instance.can_be_moved_by?(user)).to be false
      end
    end

    it 'checks write permissions on space' do
      storable_instance.space = space
      
      if space.respond_to?(:writable_by?)
        allow(space).to receive(:writable_by?).with(user).and_return(false)
        expect(storable_instance.can_be_moved_by?(user)).to be false
      end
    end
  end

  describe '#breadcrumb_path' do
    it 'returns empty array when no space' do
      storable_instance.space = nil
      expect(storable_instance.breadcrumb_path).to eq([])
    end

    it 'includes space in breadcrumb' do
      storable_instance.space = space
      breadcrumbs = storable_instance.breadcrumb_path
      
      expect(breadcrumbs.first[:name]).to eq(space.name)
      expect(breadcrumbs.first[:item]).to eq(space)
    end

    it 'includes folder hierarchy in breadcrumb' do
      storable_instance.space = space
      storable_instance.folder = child_folder
      
      breadcrumbs = storable_instance.breadcrumb_path
      
      # Should include: space -> parent_folder -> child_folder -> self
      expect(breadcrumbs.length).to eq(4)
      expect(breadcrumbs.map { |b| b[:item] }).to eq([space, parent_folder, child_folder, storable_instance])
    end
  end

  describe '#display_name' do
    it 'uses title when available' do
      if storable_instance.respond_to?(:title=)
        storable_instance.title = 'Custom Title'
        expect(storable_instance.display_name).to eq('Custom Title')
      end
    end

    it 'uses name when title not available' do
      expect(storable_instance.display_name).to eq('Test Document')
    end

    it 'falls back to class name' do
      storable_without_name = test_class.new
      allow(storable_without_name).to receive(:respond_to?).with(:title).and_return(false)
      allow(storable_without_name).to receive(:respond_to?).with(:name).and_return(false)
      
      expect(storable_without_name.display_name).to eq('Teststorable')
    end
  end

  describe '#siblings' do
    before do
      skip "Tests require documents table" unless test_class.table_exists?
    end

    it 'returns siblings in same folder' do
      item1 = test_class.new(space: space, folder: child_folder, uploaded_by: user, title: 'Item 1')
      item1.file.attach(io: StringIO.new('test'), filename: 'test1.txt', content_type: 'text/plain')
      item1.save!
      
      item2 = test_class.new(space: space, folder: child_folder, uploaded_by: user, title: 'Item 2')
      item2.file.attach(io: StringIO.new('test'), filename: 'test2.txt', content_type: 'text/plain')
      item2.save!
      
      siblings = item1.siblings
      expect(siblings).to include(item2)
      expect(siblings).not_to include(item1)
    end

    it 'returns siblings in same space root' do
      item1 = test_class.new(space: space, uploaded_by: user, title: 'Item 1')
      item1.file.attach(io: StringIO.new('test'), filename: 'test1.txt', content_type: 'text/plain')
      item1.save!
      
      item2 = test_class.new(space: space, uploaded_by: user, title: 'Item 2')
      item2.file.attach(io: StringIO.new('test'), filename: 'test2.txt', content_type: 'text/plain')
      item2.save!
      
      siblings = item1.siblings
      expect(siblings).to include(item2)
      expect(siblings).not_to include(item1)
    end
  end

  describe '#archive!' do
    it 'sets archived_at timestamp' do
      if storable_instance.respond_to?(:archived_at=)
        storable_instance.save! if storable_instance.respond_to?(:save!)
        
        travel_to(Time.current) do
          storable_instance.archive!
          expect(storable_instance.archived_at).to be_within(1.second).of(Time.current)
        end
      end
    end

    it 'archives children when applicable' do
      if storable_instance.respond_to?(:children) && storable_instance.respond_to?(:archived_at=)
        child = double('child')
        allow(child).to receive(:archive!)
        allow(storable_instance).to receive(:children).and_return([child])
        
        storable_instance.archive!
        expect(child).to have_received(:archive!)
      end
    end
  end

  describe '#restore!' do
    it 'clears archived_at timestamp' do
      if storable_instance.respond_to?(:archived_at=)
        storable_instance.archived_at = Time.current
        storable_instance.restore!
        
        expect(storable_instance.archived_at).to be_nil
      end
    end
  end

  describe '#storage_stats' do
    it 'returns comprehensive storage statistics' do
      stats = storable_instance.storage_stats
      
      expect(stats).to have_key(:size)
      expect(stats).to have_key(:total_size)
      expect(stats).to have_key(:path)
      expect(stats).to have_key(:depth)
      expect(stats).to have_key(:children_count)
    end
  end

  describe 'callbacks' do
    before do
      skip "Tests require documents table" unless test_class.table_exists?
    end

    it 'updates storage path before save' do
      item = test_class.new(space: space, folder: child_folder, uploaded_by: user, title: 'Test')
      item.file.attach(
        io: StringIO.new('test content'),
        filename: 'test.txt',
        content_type: 'text/plain'
      )
      item.save!
      
      expect(item.storage_path).to include('test-space')
      expect(item.storage_path).to include('child-folder')
    end
  end

  describe 'scopes' do
    before do
      skip "Scopes require actual database table" unless test_class.table_exists?
    end

    let!(:item_in_space) do
      item = test_class.new(space: space, uploaded_by: user, title: 'Item in Space')
      item.file.attach(io: StringIO.new('test'), filename: 'test1.txt', content_type: 'text/plain')
      item.save!
      item
    end
    
    let!(:item_in_folder) do
      item = test_class.new(space: space, folder: child_folder, uploaded_by: user, title: 'Item in Folder')
      item.file.attach(io: StringIO.new('test'), filename: 'test2.txt', content_type: 'text/plain')
      item.save!
      item
    end
    
    # Note: Documents table has NOT NULL constraint on space_id, so we can't create orphaned documents

    describe '.in_space' do
      it 'returns items in specific space' do
        items = test_class.in_space(space)
        expect(items).to include(item_in_space, item_in_folder)
      end
    end

    describe '.in_folder' do
      it 'returns items in specific folder' do
        items = test_class.in_folder(child_folder)
        expect(items).to include(item_in_folder)
        expect(items).not_to include(item_in_space)
      end
    end

    describe '.root_items' do
      it 'returns items not in any folder' do
        items = test_class.root_items
        expect(items).to include(item_in_space)
        expect(items).not_to include(item_in_folder)
      end
    end

    describe '.orphaned' do
      it 'returns items without space' do
        # Since documents table has NOT NULL constraint on space_id,
        # we can't create orphaned documents, so this should return empty
        items = test_class.orphaned
        expect(items).to be_empty
      end
    end
  end

  describe 'private methods' do
    describe '#allow_orphaned_storage?' do
      it 'delegates to class method' do
        test_class.allow_orphaned_storage(true)
        expect(storable_instance.send(:allow_orphaned_storage?)).to be true
        
        test_class.allow_orphaned_storage(false)
        expect(storable_instance.send(:allow_orphaned_storage?)).to be false
      end
    end

    describe '#storage_depth' do
      it 'returns 0 for root items' do
        expect(storable_instance.send(:storage_depth)).to eq(0)
      end

      it 'returns folder depth + 1' do
        storable_instance.folder = child_folder
        allow(child_folder).to receive(:depth).and_return(2)
        
        expect(storable_instance.send(:storage_depth)).to eq(3)
      end
    end
  end
  
  # Clean up the test class after the tests
  after(:all) do
    Object.send(:remove_const, :TestStorable) if Object.const_defined?(:TestStorable)
  end
end