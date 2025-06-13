class Navigation::NavbarComponent < ApplicationComponent
  def initialize(current_page: nil, breadcrumbs: nil)
    @current_page = current_page
    @breadcrumbs = breadcrumbs
  end

  private

  attr_reader :current_page, :breadcrumbs
  
  def current_user
    helpers.current_user
  end
  
  def navigation_service
    @navigation_service ||= NavigationService.new(current_user) if current_user
  end
  
  def unread_notifications_count
    return 0 unless current_user
    current_user.notifications.where(read_at: nil).count
  end

  def navigation_items
    # Use NavigationService if available, otherwise fallback to default
    if navigation_service
      items = navigation_service.navigation_items
      if items && items.any?
        items.map do |item|
          { 
            name: item[:label], 
            path: item[:path], 
            icon: item[:icon],
            badge: item[:badge],
            badge_color: item[:badge_color]
          }
        end
      else
        default_navigation_items
      end
    else
      default_navigation_items
    end
  end
  
  def default_navigation_items
    items = [
      { name: 'Tableau de bord', path: helpers.root_path, icon: 'home' },
      { name: 'GED', path: helpers.ged_dashboard_path, icon: 'document' },
      { name: 'Bannettes', path: helpers.baskets_path, icon: 'inbox' },
      { name: 'Tags', path: helpers.tags_path, icon: 'tag' },
      { name: 'Recherche', path: helpers.search_path, icon: 'search' }
    ]
    
    # Add ImmoPromo if user has access
    if current_user && defined?(Immo::Promo::Project) && helpers.policy(Immo::Promo::Project).index?
      items << { name: 'Immo Promo', path: '/immo/promo/projects', icon: 'building' }
    end
    
    if current_user && helpers.policy(User).index?
      items << { name: 'Utilisateurs', path: helpers.users_path, icon: 'users' }
    end
    
    if current_user && helpers.policy(UserGroup).index?
      items << { name: 'Groupes', path: helpers.user_groups_path, icon: 'user-group' }
    end
    
    items
  end
  
  def profile_specific_navigation_items
    return [] unless current_user
    
    # Since we're not using profiles system anymore, base on user role
    case current_user.role
    when 'admin', 'super_admin'
      [
        { name: 'Validations', path: helpers.validation_requests_path, icon: 'check-circle', badge: pending_validations_count, badge_color: 'red' }
      ]
    when 'manager'
      [
        { name: 'Mes projets', path: '/immo/promo/projects', icon: 'briefcase' }
      ]
    when 'user'
      [
        { name: 'Mes documents', path: helpers.ged_dashboard_path, icon: 'document-text' }
      ]
    else
      []
    end
  end
  
  def quick_links
    navigation_service&.quick_links || []
  end
  
  def has_quick_links?
    quick_links.any?
  end
  
  def show_profile_switcher?
    # Simplified - no profile switching for now
    false
  end
  
  def show_breadcrumbs?
    breadcrumbs.present? && breadcrumbs.any?
  end

  def admin_items
    [
      { name: 'Administration', path: '#', icon: 'cog' }
    ]
  end

  def user_items
    [
      { name: 'Mon profil', path: helpers.edit_user_registration_path, icon: 'user' },
      { name: 'Notifications', path: helpers.notifications_path, icon: 'bell', badge: unread_notifications_count },
      { name: 'Paramètres', path: helpers.edit_user_registration_path, icon: 'cog' },
      { name: 'Déconnexion', path: helpers.destroy_user_session_path, icon: 'logout', method: :delete }
    ]
  end

  def active_item?(path)
    return false if path == '#'
    current_page == path || (helpers.request.path.start_with?(path) if path != '/')
  end

  # Badge count methods
  def pending_validations_count
    @pending_validations_count ||= current_user.validation_requests.pending.count
  end

  def active_projects_count
    return 0 unless defined?(Immo::Promo::Project)
    @active_projects_count ||= Immo::Promo::Project
      .where(project_manager_id: current_user.id)
      .where(status: 'in_progress')
      .count
  end

  def new_leads_count
    @new_leads_count ||= Document
      .where(document_type: 'lead', status: 'new')
      .where('created_at > ?', 7.days.ago)
      .count
  end

  def compliance_alerts_count
    @compliance_alerts_count ||= begin
      count = 0
      count += Document.where('expiry_date <= ?', 30.days.from_now).where(status: 'active').count
      count += ValidationRequest.where(validation_type: 'legal', status: 'pending', assigned_to: current_user).count
      count
    end
  end

  def pending_invoices_count
    @pending_invoices_count ||= Document
      .where(document_type: 'invoice', status: 'pending')
      .count
  end

  def open_tickets_count
    @open_tickets_count ||= Document
      .where(document_type: 'support_ticket', status: ['new', 'in_progress'])
      .count
  end

  # Search placeholder based on profile
  def search_placeholder
    case current_user&.active_profile&.profile_type
    when 'direction'
      "Rechercher validations, rapports, documents..."
    when 'chef_projet'
      "Rechercher projets, documents, ressources..."
    when 'commercial'
      "Rechercher clients, propositions, contrats..."
    when 'juridique'
      "Rechercher contrats, conformité, échéances..."
    when 'finance'
      "Rechercher factures, budgets, notes..."
    when 'technique'
      "Rechercher specs, docs, tickets..."
    else
      "Rechercher documents, dossiers, espaces..."
    end
  end

  # Recent items for quick access
  def recent_items
    return [] unless current_user
    
    @recent_items ||= begin
      items = []
      
      # Recent documents
      recent_docs = current_user.documents
        .includes(:space)
        .order(updated_at: :desc)
        .limit(3)
      
      items += recent_docs.map do |doc|
        {
          type: 'document',
          name: doc.title,
          path: helpers.ged_document_path(doc),
          icon: document_icon(doc),
          time: doc.updated_at
        }
      end
      
      # Recent searches
      if current_user.search_queries&.any?
        recent_searches = current_user.search_queries
          .order(created_at: :desc)
          .limit(2)
        
        items += recent_searches.map do |search|
          {
            type: 'search',
            name: search.query,
            path: helpers.search_path(q: search.query),
            icon: 'search',
            time: search.created_at
          }
        end
      end
      
      items.sort_by { |i| i[:time] }.reverse.first(5)
    end
  end

  private

  def document_icon(document)
    case document.file_content_type
    when /pdf/ then 'document-text'
    when /image/ then 'photograph'
    when /spreadsheet|excel/ then 'table'
    when /presentation|powerpoint/ then 'presentation-chart-bar'
    else 'document'
    end
  end
end