class GedPolicy < ApplicationPolicy
  def my_documents?
    # All authenticated users can view their own documents
    user.present?
  end
  
  def statistics?
    # Only users with admin role can view statistics
    user.present? && user.admin?
  end
end