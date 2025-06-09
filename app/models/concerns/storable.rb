# Concern for managing storage location and organization
module Storable
  extend ActiveSupport::Concern

  included do
    belongs_to :space, optional: true
    belongs_to :folder, optional: true
    
    validates :space, presence: true, unless: :allow_orphaned_storage?
    validate :folder_belongs_to_space, if: :folder_id?
    
    before_save :update_storage_path
    after_save :update_descendants_paths, if: :saved_change_to_folder_id?
    
    scope :in_space, ->(space) { where(space: space) }
    scope :in_folder, ->(folder) { where(folder: folder) }
    scope :root_items, -> { where(folder: nil) }
    scope :by_path, ->(path) { where(storage_path: path) }
    scope :orphaned, -> { where(space: nil) }
  end

  class_methods do
    # Find by storage path
    def find_by_path(path)
      find_by(storage_path: path)
    end

    # Search within path
    def within_path(path)
      where('storage_path LIKE ?', "#{path}%")
    end

    # Configure if orphaned storage is allowed
    def allow_orphaned_storage(value = true)
      @allow_orphaned_storage = value
    end

    def orphaned_storage_allowed?
      @allow_orphaned_storage || false
    end
  end

  # Get full storage path
  def storage_path
    return '/' unless space
    
    path_parts = [space.slug || space.name.parameterize]
    
    if folder
      path_parts.concat(folder.ancestors.map { |f| f.slug || f.name.parameterize })
      path_parts << (folder.slug || folder.name.parameterize)
    end
    
    path_parts << (respond_to?(:slug) ? slug : name.parameterize) if respond_to?(:name)
    
    "/#{path_parts.join('/')}"
  end

  # Get parent storage container
  def storage_parent
    folder || space
  end

  # Move to different location
  def move_to(destination)
    transaction do
      case destination
      when Space
        self.space = destination
        self.folder = nil
      when Folder
        self.space = destination.space
        self.folder = destination
      when nil
        self.folder = nil
      else
        raise ArgumentError, "Invalid destination type: #{destination.class}"
      end
      
      save!
    end
  end

  # Copy to different location
  def copy_to(destination, include_content: true)
    transaction do
      new_item = self.class.new(attributes.except('id', 'created_at', 'updated_at'))
      
      case destination
      when Space
        new_item.space = destination
        new_item.folder = nil
      when Folder
        new_item.space = destination.space
        new_item.folder = destination
      else
        raise ArgumentError, "Invalid destination type: #{destination.class}"
      end
      
      # Copy file if applicable
      if include_content && respond_to?(:file) && file.attached?
        new_item.file.attach(
          io: StringIO.new(file.download),
          filename: file.filename,
          content_type: file.content_type
        )
      end
      
      new_item.save!
      new_item
    end
  end

  # Get storage size
  def storage_size
    return 0 unless respond_to?(:file) && file.attached?
    file.byte_size
  end

  # Get total size including children
  def total_storage_size
    size = storage_size
    
    if respond_to?(:children)
      size += children.sum(&:total_storage_size)
    end
    
    size
  end

  # Check if can be moved by user
  def can_be_moved_by?(user)
    return false unless user
    
    # Check write permission on current location
    return false unless writable_by?(user) if respond_to?(:writable_by?)
    
    # Check if user can write to current parent
    if folder
      return false unless folder.writable_by?(user) if folder.respond_to?(:writable_by?)
    elsif space
      return false unless space.writable_by?(user) if space.respond_to?(:writable_by?)
    end
    
    true
  end

  # Get breadcrumb path
  def breadcrumb_path
    return [] unless space
    
    path = [{ name: space.name, item: space }]
    
    if folder
      folder.ancestors.each do |ancestor|
        path << { name: ancestor.name, item: ancestor }
      end
      path << { name: folder.name, item: folder }
    end
    
    path << { name: display_name, item: self }
    path
  end

  # Display name for breadcrumbs/UI
  def display_name
    if respond_to?(:title)
      title
    elsif respond_to?(:name)
      name
    else
      self.class.name.humanize
    end
  end

  # Find items in same location
  def siblings
    if folder
      self.class.in_folder(folder)
    elsif space
      self.class.in_space(space).root_items
    else
      self.class.none
    end.where.not(id: id)
  end

  # Archive item
  def archive!
    return false unless respond_to?(:archived_at)
    
    transaction do
      update!(archived_at: Time.current)
      
      # Archive children if applicable
      if respond_to?(:children)
        children.each(&:archive!)
      end
    end
  end

  # Restore from archive
  def restore!
    return false unless respond_to?(:archived_at)
    
    update!(archived_at: nil)
  end

  # Storage statistics
  def storage_stats
    {
      size: storage_size,
      total_size: total_storage_size,
      path: storage_path,
      depth: storage_depth,
      children_count: respond_to?(:children) ? children.count : 0
    }
  end

  private

  def allow_orphaned_storage?
    self.class.orphaned_storage_allowed?
  end

  def folder_belongs_to_space
    return unless folder && space
    
    unless folder.space_id == space_id
      errors.add(:folder, 'must belong to the same space')
    end
  end

  def update_storage_path
    self.storage_path = storage_path if respond_to?(:storage_path=)
  end

  def update_descendants_paths
    return unless respond_to?(:children)
    
    children.find_each do |child|
      child.save! # This will trigger update_storage_path
    end
  end

  def storage_depth
    folder ? folder.depth + 1 : 0
  end
end