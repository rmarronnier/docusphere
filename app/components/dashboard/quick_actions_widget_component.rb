class Dashboard::QuickActionsWidgetComponent < ViewComponent::Base
  def initialize(user:)
    @user = user
  end
  
  private
  
  def quick_actions
    actions = base_actions
    actions += profile_specific_actions
    actions
  end
  
  def base_actions
    [
      {
        title: "Nouveau document",
        description: "Ajouter un fichier",
        path: helpers.ged_new_document_path,
        icon: "document-add",
        color: "blue"
      },
      # {
      #   title: "Nouveau dossier",
      #   description: "Créer un dossier",
      #   path: helpers.new_ged_folder_path,
      #   icon: "folder-add",
      #   color: "green"
      # },
      {
        title: "Recherche avancée",
        description: "Recherche détaillée",
        path: helpers.advanced_search_path,
        icon: "search",
        color: "purple"
      },
      {
        title: "Mes bannettes",
        description: "Documents favoris",
        path: helpers.baskets_path,
        icon: "inbox",
        color: "yellow"
      }
    ]
  end
  
  def profile_specific_actions
    actions = []
    
    case @user.active_profile&.profile_type
    when 'direction'
      actions << {
        title: "Validations",
        description: "Documents à valider",
        path: helpers.validation_requests_path,
        icon: "check-circle",
        color: "red"
      }
      actions << {
        title: "Rapports",
        description: "Tableaux de bord",
        path: helpers.reports_path,
        icon: "chart",
        color: "indigo"
      }
    when 'chef_projet'
      actions << {
        title: "Mes projets",
        description: "Projets en cours",
        path: helpers.immo_promo_engine.projects_path,
        icon: "briefcase",
        color: "indigo"
      }
      actions << {
        title: "Planning",
        description: "Vue planning",
        path: helpers.planning_path,
        icon: "calendar",
        color: "pink"
      }
    when 'commercial'
      actions << {
        title: "Clients",
        description: "Gestion clients",
        path: helpers.clients_path,
        icon: "users",
        color: "orange"
      }
      actions << {
        title: "Propositions",
        description: "Devis et contrats",
        path: helpers.proposals_path,
        icon: "document-text",
        color: "teal"
      }
    when 'juridique'
      actions << {
        title: "Contrats",
        description: "Suivi contrats",
        path: helpers.contracts_path,
        icon: "clipboard-check",
        color: "red"
      }
      actions << {
        title: "Conformité",
        description: "Documents légaux",
        path: helpers.compliance_path,
        icon: "shield-check",
        color: "gray"
      }
    end
    
    actions
  end
  
  def action_icon_svg(icon_name)
    case icon_name
    when "document-add"
      '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 13h6m-3-3v6m5 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>'
    when "folder-add"
      '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 13h6m-3-3v6m-9 1V7a2 2 0 012-2h6l2 2h6a2 2 0 012 2v8a2 2 0 01-2 2H5a2 2 0 01-2-2z"></path>'
    when "search"
      '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>'
    when "inbox"
      '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"></path>'
    when "check-circle"
      '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>'
    when "chart"
      '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>'
    when "briefcase"
      '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path>'
    when "calendar"
      '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path>'
    when "users"
      '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"></path>'
    when "document-text"
      '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>'
    when "clipboard-check"
      '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"></path>'
    when "shield-check"
      '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"></path>'
    else
      '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z"></path>'
    end
  end
  
  def action_color_classes(color)
    case color
    when "blue"
      "bg-blue-50 text-blue-600 hover:bg-blue-100"
    when "green"
      "bg-green-50 text-green-600 hover:bg-green-100"
    when "purple"
      "bg-purple-50 text-purple-600 hover:bg-purple-100"
    when "yellow"
      "bg-yellow-50 text-yellow-600 hover:bg-yellow-100"
    when "red"
      "bg-red-50 text-red-600 hover:bg-red-100"
    when "indigo"
      "bg-indigo-50 text-indigo-600 hover:bg-indigo-100"
    when "pink"
      "bg-pink-50 text-pink-600 hover:bg-pink-100"
    when "orange"
      "bg-orange-50 text-orange-600 hover:bg-orange-100"
    when "teal"
      "bg-teal-50 text-teal-600 hover:bg-teal-100"
    when "gray"
      "bg-gray-50 text-gray-600 hover:bg-gray-100"
    else
      "bg-gray-50 text-gray-600 hover:bg-gray-100"
    end
  end
end