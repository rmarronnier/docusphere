# @label Empty State Component
class Ui::EmptyStateComponentPreview < Lookbook::Preview
  layout "application"
  
  # @label Default Empty State
  def default
    render Ui::DataGridComponent::EmptyStateComponent.new
  end
  
  # @label With Custom Message
  def custom_message
    render Ui::DataGridComponent::EmptyStateComponent.new(
      message: "Aucun document trouvé dans ce dossier"
    )
  end
  
  # @label Icon Variations
  def icon_variations
    content_tag :div, class: "grid grid-cols-2 gap-8" do
      safe_join([
        content_tag(:div, class: "border rounded-lg p-4") do
          render Ui::DataGridComponent::EmptyStateComponent.new(
            icon: "document",
            message: "Aucun document"
          )
        end,
        
        content_tag(:div, class: "border rounded-lg p-4") do
          render Ui::DataGridComponent::EmptyStateComponent.new(
            icon: "folder",
            message: "Dossier vide"
          )
        end,
        
        content_tag(:div, class: "border rounded-lg p-4") do
          render Ui::DataGridComponent::EmptyStateComponent.new(
            icon: "search",
            message: "Aucun résultat"
          )
        end,
        
        content_tag(:div, class: "border rounded-lg p-4") do
          render Ui::DataGridComponent::EmptyStateComponent.new(
            icon: "users",
            message: "Aucun utilisateur"
          )
        end
      ])
    end
  end
  
  # @label Without Icon
  def without_icon
    render Ui::DataGridComponent::EmptyStateComponent.new(
      message: "Aucune donnée disponible",
      show_icon: false
    )
  end
  
  # @label Custom Content Simple
  def custom_content_simple
    custom_html = %(<div class="text-center">
      <h3 class="text-lg font-medium text-gray-900 mb-2">Commencez dès maintenant</h3>
      <p class="text-gray-500">Créez votre premier document pour démarrer</p>
    </div>).html_safe
    
    render Ui::DataGridComponent::EmptyStateComponent.new(
      custom_content: custom_html
    )
  end
  
  # @label Custom Content with Action
  def custom_content_with_action
    custom_html = %(<div class="text-center py-8">
      <svg class="mx-auto h-12 w-12 text-gray-400 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
      </svg>
      <h3 class="text-lg font-medium text-gray-900 mb-2">Aucun projet</h3>
      <p class="text-gray-500 mb-4">Commencez par créer votre premier projet</p>
      <button class="btn btn-primary">
        <svg class="w-5 h-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
        </svg>
        Nouveau projet
      </button>
    </div>).html_safe
    
    render Ui::DataGridComponent::EmptyStateComponent.new(
      custom_content: custom_html
    )
  end
  
  # @label Search Empty State
  def search_empty_state
    custom_html = %(<div class="text-center py-12">
      <svg class="mx-auto h-16 w-16 text-gray-300 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
      </svg>
      <h3 class="text-lg font-medium text-gray-900 mb-2">Aucun résultat trouvé</h3>
      <p class="text-gray-500 mb-6 max-w-md mx-auto">
        Nous n'avons trouvé aucun document correspondant à votre recherche "rapport financier 2024"
      </p>
      <div class="space-y-2">
        <p class="text-sm text-gray-600">Suggestions :</p>
        <ul class="text-sm text-gray-500 space-y-1">
          <li>• Vérifiez l'orthographe des mots-clés</li>
          <li>• Essayez des termes plus généraux</li>
          <li>• Utilisez moins de mots-clés</li>
        </ul>
        <div class="pt-4">
          <button class="btn btn-secondary">Réinitialiser la recherche</button>
        </div>
      </div>
    </div>).html_safe
    
    render Ui::DataGridComponent::EmptyStateComponent.new(
      custom_content: custom_html
    )
  end
  
  # @label Filter Empty State
  def filter_empty_state
    custom_html = %(<div class="text-center py-8">
      <svg class="mx-auto h-12 w-12 text-gray-400 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z" />
      </svg>
      <h3 class="text-lg font-medium text-gray-900 mb-2">Aucun résultat avec ces filtres</h3>
      <p class="text-gray-500 mb-4">Essayez de modifier vos critères de filtrage</p>
      <div class="flex justify-center space-x-2">
        <button class="btn btn-sm btn-secondary">Réinitialiser les filtres</button>
        <button class="btn btn-sm btn-primary">Modifier les filtres</button>
      </div>
    </div>).html_safe
    
    render Ui::DataGridComponent::EmptyStateComponent.new(
      custom_content: custom_html
    )
  end
  
  # @label Permission Empty State
  def permission_empty_state
    custom_html = %(<div class="text-center py-12">
      <svg class="mx-auto h-16 w-16 text-gray-300 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
      </svg>
      <h3 class="text-lg font-medium text-gray-900 mb-2">Accès restreint</h3>
      <p class="text-gray-500 mb-4">Vous n'avez pas les permissions nécessaires pour voir ces documents</p>
      <button class="btn btn-secondary">Demander l'accès</button>
    </div>).html_safe
    
    render Ui::DataGridComponent::EmptyStateComponent.new(
      custom_content: custom_html
    )
  end
end