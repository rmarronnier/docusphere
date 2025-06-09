# Concern for adding linking capabilities between models
module Linkable
  extend ActiveSupport::Concern

  included do
    has_many :source_links, class_name: 'Link', as: :source, dependent: :destroy
    has_many :target_links, class_name: 'Link', as: :target, dependent: :destroy
    
    scope :linked_to, ->(target) {
      joins(:source_links).where(links: { target: target })
    }
    scope :linked_from, ->(source) {
      joins(:target_links).where(links: { source: source })
    }
    scope :with_link_type, ->(type) {
      joins('LEFT JOIN links AS source_links ON source_links.source_type = \'#{self.name}\' AND source_links.source_id = #{table_name}.id')
        .joins('LEFT JOIN links AS target_links ON target_links.target_type = \'#{self.name}\' AND target_links.target_id = #{table_name}.id')
        .where('source_links.link_type = ? OR target_links.link_type = ?', type, type)
        .distinct
    }
  end

  # Create a link to another object
  def link_to(target, link_type: 'related', metadata: {})
    return false if target == self
    return false if linked_to?(target, link_type: link_type)
    
    source_links.create!(
      target: target,
      link_type: link_type,
      metadata: metadata
    )
  end

  # Create a bidirectional link
  def link_with(target, link_type: 'related', metadata: {})
    return false if target == self
    
    transaction do
      link_to(target, link_type: link_type, metadata: metadata)
      target.link_to(self, link_type: link_type, metadata: metadata)
    end
  end

  # Remove a link
  def unlink_from(target, link_type: nil)
    scope = source_links.where(target: target)
    scope = scope.where(link_type: link_type) if link_type
    scope.destroy_all
  end

  # Remove bidirectional link
  def unlink_with(target, link_type: nil)
    transaction do
      unlink_from(target, link_type: link_type)
      target.unlink_from(self, link_type: link_type)
    end
  end

  # Check if linked to target
  def linked_to?(target, link_type: nil)
    scope = source_links.where(target: target)
    scope = scope.where(link_type: link_type) if link_type
    scope.exists?
  end

  # Check if linked from source
  def linked_from?(source, link_type: nil)
    scope = target_links.where(source: source)
    scope = scope.where(link_type: link_type) if link_type
    scope.exists?
  end

  # Check if linked with (bidirectional)
  def linked_with?(other, link_type: nil)
    linked_to?(other, link_type: link_type) && linked_from?(other, link_type: link_type)
  end

  # Get all linked objects (as source)
  def linked_targets(link_type: nil)
    scope = source_links.includes(:target)
    scope = scope.where(link_type: link_type) if link_type
    scope.map(&:target)
  end

  # Get all linked objects (as target)
  def linked_sources(link_type: nil)
    scope = target_links.includes(:source)
    scope = scope.where(link_type: link_type) if link_type
    scope.map(&:source)
  end

  # Get all linked objects (both directions)
  def all_linked_objects(link_type: nil)
    (linked_targets(link_type: link_type) + linked_sources(link_type: link_type)).uniq
  end

  # Get links grouped by type
  def links_by_type
    all_links = source_links + target_links
    all_links.group_by(&:link_type)
  end

  # Get related objects (convenience method)
  def related_objects
    linked_targets(link_type: 'related')
  end

  # Get parent objects
  def parent_objects
    linked_sources(link_type: 'child')
  end

  # Get child objects
  def child_objects
    linked_targets(link_type: 'child')
  end

  # Get referenced objects
  def referenced_objects
    linked_targets(link_type: 'reference')
  end

  # Get objects that reference this
  def referencing_objects
    linked_sources(link_type: 'reference')
  end

  # Create parent-child relationship
  def add_child(child)
    link_to(child, link_type: 'child')
  end

  def set_parent(parent)
    parent.link_to(self, link_type: 'child')
  end

  # Create reference relationship
  def add_reference(target)
    link_to(target, link_type: 'reference')
  end

  # Get link to specific target
  def link_to_target(target)
    source_links.find_by(target: target)
  end

  # Get link from specific source
  def link_from_source(source)
    target_links.find_by(source: source)
  end

  # Update link metadata
  def update_link_metadata(target, metadata)
    link = link_to_target(target)
    return false unless link
    
    link.update!(metadata: link.metadata.merge(metadata))
  end

  # Get link chain (follow links of same type)
  def link_chain(link_type: 'related', direction: :forward, max_depth: 10)
    visited = Set.new([self])
    chain = [self]
    current = self
    depth = 0
    
    while depth < max_depth
      next_objects = if direction == :forward
        current.linked_targets(link_type: link_type)
      else
        current.linked_sources(link_type: link_type)
      end
      
      next_object = next_objects.find { |obj| !visited.include?(obj) }
      break unless next_object
      
      visited.add(next_object)
      chain << next_object
      current = next_object
      depth += 1
    end
    
    chain
  end

  # Find shortest path to target
  def shortest_path_to(target, link_type: nil, max_depth: 10)
    return [] if self == target
    
    queue = [[self]]
    visited = Set.new([self])
    
    while !queue.empty? && queue.first.length <= max_depth
      path = queue.shift
      current = path.last
      
      neighbors = current.all_linked_objects(link_type: link_type)
      
      neighbors.each do |neighbor|
        next if visited.include?(neighbor)
        
        new_path = path + [neighbor]
        return new_path if neighbor == target
        
        visited.add(neighbor)
        queue.push(new_path)
      end
    end
    
    [] # No path found
  end

  # Link statistics
  def link_stats
    {
      total_links: source_links.count + target_links.count,
      outgoing_links: source_links.count,
      incoming_links: target_links.count,
      link_types: links_by_type.transform_values(&:count),
      unique_linked_objects: all_linked_objects.count
    }
  end
end