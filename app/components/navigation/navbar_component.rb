class Navigation::NavbarComponent < ApplicationComponent
  def initialize(current_page: nil)
    @current_page = current_page
  end

  private

  attr_reader :current_page

  def navigation_items
    [
      { name: 'Tableau de bord', path: root_path, icon: 'home' },
      { name: 'Documents', path: '#', icon: 'document' },
      { name: 'Espaces', path: '#', icon: 'folder' },
      { name: 'Workflows', path: '#', icon: 'workflow' },
      { name: 'Bannettes', path: '#', icon: 'inbox' },
      { name: 'Recherche', path: '#', icon: 'search' }
    ]
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
    current_page == path || request.path.start_with?(path)
  end
end