class Navigation::NavbarComponent < ApplicationComponent
  def initialize(current_page: nil)
    @current_page = current_page
  end

  private

  attr_reader :current_page
  
  def unread_notifications_count
    return 0 unless helpers.current_user
    helpers.current_user.notifications.where(read_at: nil).count
  end

  def navigation_items
    items = [
      { name: 'Tableau de bord', path: root_path, icon: 'home' },
      { name: 'GED', path: helpers.ged_dashboard_path, icon: 'document' },
      { name: 'Bannettes', path: helpers.baskets_path, icon: 'inbox' },
      { name: 'Tags', path: helpers.tags_path, icon: 'tag' },
      { name: 'Recherche', path: helpers.search_path, icon: 'search' }
    ]
    
    # Add ImmoPromo if user has access
    if helpers.current_user&.has_permission?('immo_promo:access')
      items << { name: 'Immo Promo', path: '/immo/promo/projects', icon: 'building' }
    end
    
    if helpers.current_user&.admin? || helpers.current_user&.super_admin?
      items << { name: 'Utilisateurs', path: helpers.users_path, icon: 'users' }
      items << { name: 'Groupes', path: helpers.user_groups_path, icon: 'user-group' }
    end
    
    items
  end

  def admin_items
    [
      { name: 'Administration', path: '#', icon: 'cog' }
    ]
  end

  def user_items
    [
      { name: 'Mon profil', path: edit_user_registration_path, icon: 'user' },
      { name: 'Déconnexion', path: destroy_user_session_path, icon: 'logout', method: :delete }
    ]
  end

  def active_item?(path)
    return false if path == '#'
    current_page == path || (helpers.request.path.start_with?(path) if path != '/')
  end
end