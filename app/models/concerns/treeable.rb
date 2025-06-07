module Treeable
  extend ActiveSupport::Concern

  included do
    belongs_to :parent, class_name: name, optional: true
    has_many :children, class_name: name, foreign_key: 'parent_id', dependent: :destroy

    scope :roots, -> { where(parent_id: nil) }
    scope :with_children, -> { includes(:children) }

    before_validation :ensure_not_circular_reference
    validate :parent_cannot_be_self
  end

  def root?
    parent_id.nil?
  end

  def leaf?
    children.empty?
  end

  def ancestors
    return [] if root?
    
    ancestors = []
    current = parent
    while current
      ancestors.unshift(current)
      current = current.parent
    end
    ancestors
  end

  def root
    return self if root?
    ancestors.first
  end

  def descendants
    children.includes(:children).flat_map { |child| [child] + child.descendants }
  end

  def siblings
    return self.class.roots if root?
    parent.children.where.not(id: id)
  end

  def depth
    ancestors.count
  end

  def path
    ancestors + [self]
  end

  def path_names
    path.map(&:name).join(' / ')
  end

  def can_be_parent_of?(other)
    return false if other == self
    return false if descendants.include?(other)
    true
  end

  private

  def ensure_not_circular_reference
    if parent_id_changed? && parent_id.present?
      errors.add(:parent, "cannot be a descendant of itself") if descendants.map(&:id).include?(parent_id)
    end
  end

  def parent_cannot_be_self
    errors.add(:parent, "cannot be itself") if parent == self
  end
end