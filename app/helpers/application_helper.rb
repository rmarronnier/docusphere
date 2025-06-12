module ApplicationHelper
  # Routes helpers pour dashboard
  
  def validation_requests_path
    ged_document_validations_path(Document.first) rescue "#"
  end
  
  def reports_path
    "#reports"
  end
  
  def planning_path
    "#planning"
  end
  
  def clients_path
    "#clients"
  end
  
  def proposals_path
    "#proposals"
  end
  
  def contracts_path
    "#contracts"
  end
  
  def compliance_path
    "#compliance"
  end
  
  def help_path
    "#help"
  end
  
  def statistics_path
    "#statistics"
  end
  
  def ged_activities_path
    ged_documents_path
  end
end
