module ApplicationHelper
  # Flash messages helper
  def render_flash_messages
    flash_html = []
    
    flash.each do |type, message|
      next if message.blank?
      
      flash_html << render(Ui::FlashAlertComponent.new(
        type: type,
        message: message,
        dismissible: true,
        show_icon: true,
        html_safe: message.html_safe?
      ))
    end
    
    safe_join(flash_html)
  end
  
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

  # Breadcrumb helper for easy component usage
  def breadcrumb_component(items, **options)
    # Set GED-specific defaults
    ged_defaults = {
      separator: :ged,
      show_home: false,
      mobile_back: false
    }
    
    # Merge defaults with provided options
    final_options = ged_defaults.merge(options)
    
    render Navigation::BreadcrumbComponent.new(
      items: items,
      **final_options
    )
  end

  # Helper to create GED breadcrumbs in standard format
  def ged_breadcrumb(items, options = {})
    breadcrumb_component(items, **options)
  end
end
