class NavigationService
  attr_reader :user, :profile
  
  def initialize(user)
    @user = user
    @profile = user.respond_to?(:active_profile) ? user.active_profile : user.try(:current_profile)
  end
  
  def navigation_items
    case profile&.profile_type
    when 'direction'
      direction_navigation
    when 'chef_projet'
      chef_projet_navigation
    when 'juriste'
      juriste_navigation
    when 'architecte'
      architecte_navigation
    when 'commercial'
      commercial_navigation
    when 'controleur'
      controleur_navigation
    else
      default_navigation
    end
  end
  
  def quick_links
    case profile&.profile_type
    when 'direction'
      direction_quick_links
    when 'chef_projet'
      chef_projet_quick_links
    when 'juriste'
      juriste_quick_links
    else
      default_quick_links
    end
  end
  
  def breadcrumb_for(path)
    breadcrumb = [{ name: 'Accueil', path: '/' }]
    
    # Parse the path and build breadcrumb
    segments = path.split('/').reject(&:blank?)
    current_path = ''
    
    segments.each_with_index do |segment, index|
      current_path += "/#{segment}"
      is_last = index == segments.size - 1
      
      breadcrumb << {
        name: humanize_segment(segment, current_path),
        path: current_path,
        current: is_last
      }
    end
    
    breadcrumb
  end
  
  def can_access?(path)
    return true unless profile
    
    allowed_paths = case profile.profile_type
    when 'direction'
      ['/dashboard', '/immo/promo', '/ged', '/validations', '/reports', '/users']
    when 'chef_projet'
      ['/dashboard', '/immo/promo/projects', '/immo/promo/coordination', '/ged', '/tasks']
    when 'juriste'
      ['/dashboard', '/ged/folders/legal', '/immo/promo/permits', '/validations/legal']
    when 'commercial'
      ['/dashboard', '/immo/promo/commercial-dashboard', '/immo/promo/reservations', '/ged/commercial']
    else
      ['/dashboard', '/ged', '/search']
    end
    
    allowed_paths.any? { |allowed| path.start_with?(allowed) }
  end
  
  private
  
  def direction_navigation
    [
      {
        label: 'Vue d\'ensemble',
        path: '/dashboard/overview',
        icon: 'home',
        badge: nil
      },
      {
        label: 'Rapports stratégiques',
        path: '/reports/strategic',
        icon: 'chart-bar'
      },
      {
        label: 'Validation documents',
        path: '/validations',
        icon: 'check-circle',
        badge: pending_validations_count
      },
      {
        label: 'Portefeuille projets',
        path: '/immo/promo/projects',
        icon: 'briefcase'
      },
      {
        label: 'Documents',
        path: '/ged',
        icon: 'folder'
      },
      {
        label: 'Administration',
        path: '/admin',
        icon: 'cog'
      }
    ]
  end
  
  def chef_projet_navigation
    [
      {
        label: 'Tableau de bord',
        path: '/dashboard',
        icon: 'home'
      },
      {
        label: 'Mes projets',
        path: '/immo/promo/projects',
        icon: 'folder',
        badge: active_projects_count
      },
      {
        label: 'Tâches',
        path: '/tasks',
        icon: 'check-square',
        badge: pending_tasks_count
      },
      {
        label: 'Planning',
        path: '/planning',
        icon: 'calendar'
      },
      {
        label: 'Documents',
        path: '/ged',
        icon: 'document'
      },
      {
        label: 'Équipe',
        path: '/immo/promo/stakeholders',
        icon: 'users'
      }
    ]
  end
  
  def juriste_navigation
    [
      {
        label: 'Tableau de bord',
        path: '/dashboard',
        icon: 'home'
      },
      {
        label: 'Documents juridiques',
        path: '/documents/legal',
        icon: 'scale'
      },
      {
        label: 'Contrats',
        path: '/contracts',
        icon: 'clipboard-list'
      },
      {
        label: 'Conformité',
        path: '/compliance',
        icon: 'shield-check'
      },
      {
        label: 'Autorisations',
        path: '/immo/promo/permits',
        icon: 'document-text',
        badge: pending_permits_count
      }
    ]
  end
  
  def architecte_navigation
    [
      {
        label: 'Tableau de bord',
        path: '/dashboard',
        icon: 'home'
      },
      {
        label: 'Projets',
        path: '/immo/promo/projects',
        icon: 'cube'
      },
      {
        label: 'Plans',
        path: '/ged/folders/plans',
        icon: 'map'
      },
      {
        label: 'Spécifications',
        path: '/specifications',
        icon: 'document-duplicate'
      },
      {
        label: 'Validations techniques',
        path: '/validations/technical',
        icon: 'clipboard-check'
      }
    ]
  end
  
  def commercial_navigation
    [
      {
        label: 'Tableau de bord',
        path: '/dashboard',
        icon: 'home'
      },
      {
        label: 'Tableau commercial',
        path: '/immo/promo/commercial-dashboard',
        icon: 'trending-up'
      },
      {
        label: 'Réservations',
        path: '/immo/promo/reservations',
        icon: 'shopping-cart',
        badge: new_reservations_count
      },
      {
        label: 'Clients',
        path: '/clients',
        icon: 'user-group'
      },
      {
        label: 'Documents commerciaux',
        path: '/ged/commercial',
        icon: 'document-text'
      }
    ]
  end
  
  def controleur_navigation
    [
      {
        label: 'Tableau de bord',
        path: '/dashboard',
        icon: 'home'
      },
      {
        label: 'Suivi budgétaire',
        path: '/immo/promo/budgets',
        icon: 'calculator'
      },
      {
        label: 'Tableau financier',
        path: '/immo/promo/financial-dashboard',
        icon: 'chart-pie'
      },
      {
        label: 'Factures',
        path: '/invoices',
        icon: 'receipt-tax'
      },
      {
        label: 'Rapports',
        path: '/reports/financial',
        icon: 'document-report'
      }
    ]
  end
  
  def default_navigation
    [
      {
        label: 'Tableau de bord',
        path: '/dashboard',
        icon: 'home'
      },
      {
        label: 'Documents',
        path: '/ged',
        icon: 'folder'
      },
      {
        label: 'Recherche',
        path: '/search',
        icon: 'search'
      },
      {
        label: 'Notifications',
        path: '/notifications',
        icon: 'bell',
        badge: unread_notifications_count
      }
    ]
  end
  
  def direction_quick_links
    [
      { title: 'Nouveau projet', link: '/immo/promo/projects/new', icon: 'plus', color: 'blue' },
      { title: 'Validations urgentes', link: '/validations?urgency=high', icon: 'exclamation', color: 'red' },
      { title: 'Rapport mensuel', link: '/reports/monthly', icon: 'document-report', color: 'green' },
      { title: 'Réunion équipe', link: '/calendar?type=meeting', icon: 'calendar', color: 'purple' },
      { title: 'Tableau financier', link: '/immo/promo/financial-dashboard', icon: 'chart-pie', color: 'yellow' },
      { title: 'Messages', link: '/messages', icon: 'mail', color: 'gray' }
    ]
  end
  
  def chef_projet_quick_links
    [
      { title: 'Nouvelle tâche', link: '/tasks/new', icon: 'plus-circle', color: 'blue' },
      { title: 'Planning jour', link: '/immo/promo/coordination/today', icon: 'calendar', color: 'green' },
      { title: 'Upload document', link: '/ged/upload', icon: 'upload', color: 'purple' },
      { title: 'Rapport avancement', link: '/reports/progress', icon: 'chart-bar', color: 'yellow' },
      { title: 'Équipe projet', link: '/immo/promo/stakeholders', icon: 'users', color: 'pink' },
      { title: 'Notes', link: '/notes', icon: 'pencil', color: 'gray' }
    ]
  end
  
  def juriste_quick_links
    [
      { title: 'Nouveau contrat', link: '/contracts/new', icon: 'document-add', color: 'blue' },
      { title: 'Permis urgents', link: '/immo/promo/permits?status=urgent', icon: 'exclamation-circle', color: 'red' },
      { title: 'Veille juridique', link: '/legal-watch', icon: 'newspaper', color: 'green' },
      { title: 'Modèles', link: '/templates/legal', icon: 'duplicate', color: 'purple' },
      { title: 'Agenda juridique', link: '/calendar/legal', icon: 'calendar', color: 'yellow' },
      { title: 'Recherche', link: '/search/legal', icon: 'search', color: 'gray' }
    ]
  end
  
  def default_quick_links
    [
      { title: 'Mes documents', link: '/ged/my-documents', icon: 'folder-open', color: 'blue' },
      { title: 'Upload', link: '/ged/upload', icon: 'upload', color: 'green' },
      { title: 'Recherche', link: '/search', icon: 'search', color: 'purple' },
      { title: 'Aide', link: '/help', icon: 'question-mark-circle', color: 'gray' }
    ]
  end
  
  def humanize_segment(segment, path)
    case segment
    when 'ged' then 'Documents'
    when 'immo' then 'Immobilier'
    when 'promo' then 'Promotion'
    when 'projects' then 'Projets'
    when 'phases' then 'Phases'
    when 'permits' then 'Autorisations'
    when 'budgets' then 'Budgets'
    when /^\d+$/ then fetch_resource_name(path, segment)
    else segment.humanize
    end
  end
  
  def fetch_resource_name(path, id)
    # In a real implementation, this would fetch the actual resource name
    # For now, return a generic name
    if path.include?('/projects/')
      "Projet ##{id}"
    else
      "##{id}"
    end
  end
  
  # Badge counters (to be implemented with actual queries)
  def pending_validations_count
    @pending_validations_count ||= DocumentValidation.where(validator: user, status: 'pending').count
  end
  
  def active_projects_count
    # To be implemented when Immo::Promo is integrated
    0
  end
  
  def pending_tasks_count
    # To be implemented when tasks are available
    0
  end
  
  def pending_permits_count
    # To be implemented when Immo::Promo is integrated
    0
  end
  
  def new_reservations_count
    # To be implemented when Immo::Promo is integrated
    0
  end
  
  def unread_notifications_count
    @unread_notifications_count ||= begin
      if user.respond_to?(:notifications)
        notifications = user.notifications
        if notifications.respond_to?(:unread)
          notifications.unread.count
        elsif notifications.respond_to?(:where)
          notifications.where(read_at: nil).count
        else
          0
        end
      else
        0
      end
    end
  end
end