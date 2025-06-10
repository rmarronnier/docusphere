# Concern for standardized ownership checking
module Ownership
  extend ActiveSupport::Concern

  class_methods do
    # Configure which attribute(s) define ownership for this model
    def owned_by(*attributes)
      @ownership_attributes = attributes.map(&:to_sym)
    end

    # Get configured ownership attributes
    def ownership_attributes
      @ownership_attributes || [:user]
    end
  end

  # Check if the record is owned by the given user
  def owned_by?(user)
    return false unless user

    # Check each configured ownership attribute
    self.class.ownership_attributes.each do |attr|
      if respond_to?(attr)
        owner = send(attr)
        return true if owner == user
      end
    end

    false
  end

  # Get the owner(s) of this record
  def owners
    owners = []
    
    self.class.ownership_attributes.each do |attr|
      if respond_to?(attr)
        owner = send(attr)
        owners << owner if owner
      end
    end
    
    owners.compact.uniq
  end

  # Get the primary owner (first configured attribute)
  def owner
    self.class.ownership_attributes.each do |attr|
      if respond_to?(attr)
        owner = send(attr)
        return owner if owner
      end
    end
    
    nil
  end
end