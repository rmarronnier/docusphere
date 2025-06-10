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
            icon: item[:icon] 
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
      { name: 'Tableau de bord', path: root_path, icon: 'home' },
      { name: 'GED', path: ged_dashboard_path, icon: 'document' },
      { name: 'Bannettes', path: baskets_path, icon: 'inbox' },
      { name: 'Tags', path: tags_path, icon: 'tag' },
      { name: 'Recherche', path: search_path, icon: 'search' }
    ]
    
    # Add ImmoPromo if user has access
    if current_user&.has_permission?('immo_promo:access')
      items << { name: 'Immo Promo', path: '/immo/promo/projects', icon: 'building' }
    end
    
    if current_user&.admin? || current_user&.super_admin?
      items << { name: 'Utilisateurs', path: users_path, icon: 'users' }
      items << { name: 'Groupes', path: user_groups_path, icon: 'user-group' }
    end
    
    items
  end
  
  def quick_links
    navigation_service&.quick_links || []
  end
  
  def has_quick_links?
    quick_links.any?
  end
  
  def show_profile_switcher?
    current_user && current_user.user_profiles.count > 1
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
      { name: 'Mon profil', path: edit_user_registration_path, icon: 'user' },
      { name: 'Notifications', path: notifications_path, icon: 'bell' },
      { name: 'Paramètres', path: edit_user_registration_path, icon: 'cog' },
      { name: 'Déconnexion', path: destroy_user_session_path, icon: 'logout', method: :delete }
    ]
  end

  def active_item?(path)
    return false if path == '#'
    current_page == path || (helpers.request.path.start_with?(path) if path != '/')
  end
end