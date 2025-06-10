# @label DataGrid Component
class Ui::DataGridComponentPreview < Lookbook::Preview
  layout "application"
  
  # @label Default Grid
  # @display viewport desktop
  def default
    data = sample_data
    
    render Ui::DataGridComponent.new(data: data) do |grid|
      grid.with_column(key: :name, label: "Nom", sortable: true)
      grid.with_column(key: :email, label: "Email")
      grid.with_column(key: :status, label: "Statut", align: :center)
      grid.with_column(key: :created_at, label: "Date création", format: :date)
    end
  end
  
  # @label With Actions (Inline)
  def with_inline_actions
    data = sample_data
    
    render Ui::DataGridComponent.new(data: data) do |grid|
      grid.with_column(key: :name, label: "Nom")
      grid.with_column(key: :email, label: "Email")
      grid.with_column(key: :status, label: "Statut")
      
      grid.with_action(label: "Voir", path: ->(item) { "#view-#{item[:id]}" })
      grid.with_action(label: "Modifier", path: ->(item) { "#edit-#{item[:id]}" }, class: "text-blue-600")
      grid.with_action(label: "Supprimer", path: ->(item) { "#delete-#{item[:id]}" }, class: "text-red-600", method: :delete, confirm: "Êtes-vous sûr ?")
    end
  end
  
  # @label With Actions (Dropdown)
  def with_dropdown_actions
    data = sample_data
    
    render Ui::DataGridComponent.new(data: data) do |grid|
      grid.with_column(key: :name, label: "Nom")
      grid.with_column(key: :email, label: "Email")
      grid.with_column(key: :status, label: "Statut")
      
      grid.configure_actions(style: :dropdown, dropdown_label: "Actions")
      grid.with_action(label: "Voir détails", path: ->(item) { "#view-#{item[:id]}" })
      grid.with_action(label: "Modifier", path: ->(item) { "#edit-#{item[:id]}" })
      grid.with_action(label: "Dupliquer", path: ->(item) { "#duplicate-#{item[:id]}" })
      grid.with_action(label: "Archiver", path: ->(item) { "#archive-#{item[:id]}" })
      grid.with_action(label: "Supprimer", path: ->(item) { "#delete-#{item[:id]}" }, class: "text-red-600")
    end
  end
  
  # @label With Actions (Buttons)
  def with_button_actions
    data = sample_data
    
    render Ui::DataGridComponent.new(data: data) do |grid|
      grid.with_column(key: :name, label: "Nom")
      grid.with_column(key: :email, label: "Email")
      grid.with_column(key: :status, label: "Statut")
      
      grid.configure_actions(style: :buttons, size: :small, show_labels: true)
      grid.with_action(label: "Voir", path: ->(item) { "#view-#{item[:id]}" }, variant: :primary)
      grid.with_action(label: "Modifier", path: ->(item) { "#edit-#{item[:id]}" }, variant: :secondary)
    end
  end
  
  # @label With Formatting
  def with_formatting
    data = financial_data
    
    render Ui::DataGridComponent.new(data: data) do |grid|
      grid.with_column(key: :product, label: "Produit")
      grid.with_column(key: :price, label: "Prix", format: :currency, align: :right)
      grid.with_column(key: :discount, label: "Remise", format: :percentage, align: :right)
      grid.with_column(key: :in_stock, label: "En stock", format: :boolean, align: :center)
      grid.with_column(key: :last_sale, label: "Dernière vente", format: :date)
      grid.with_column(key: :status, label: "Statut", format: ->(value) { 
        content_tag(:span, value.upcase, class: status_class(value))
      })
    end
  end
  
  # @label With Selection
  def with_selection
    data = sample_data
    
    render Ui::DataGridComponent.new(
      data: data, 
      selectable: true,
      selected: [1, 3]
    ) do |grid|
      grid.with_column(key: :name, label: "Nom")
      grid.with_column(key: :email, label: "Email")
      grid.with_column(key: :status, label: "Statut")
    end
  end
  
  # @label Empty State (Default)
  def empty_default
    render Ui::DataGridComponent.new(data: []) do |grid|
      grid.with_column(key: :name, label: "Nom")
      grid.with_column(key: :email, label: "Email")
      grid.with_column(key: :status, label: "Statut")
    end
  end
  
  # @label Empty State (Custom Message)
  def empty_custom_message
    render Ui::DataGridComponent.new(data: []) do |grid|
      grid.with_column(key: :name, label: "Nom")
      grid.with_column(key: :email, label: "Email")
      
      grid.configure_empty_state(
        message: "Aucun utilisateur trouvé",
        icon: "users",
        show_icon: true
      )
    end
  end
  
  # @label Empty State (Custom Content)
  def empty_custom_content
    render Ui::DataGridComponent.new(data: []) do |grid|
      grid.with_column(key: :name, label: "Nom")
      grid.with_column(key: :email, label: "Email")
      
      grid.with_empty_state do
        content_tag :div, class: "text-center py-8" do
          safe_join([
            content_tag(:h3, "Aucun résultat", class: "text-lg font-medium text-gray-900 mb-2"),
            content_tag(:p, "Essayez de modifier vos critères de recherche", class: "text-gray-500 mb-4"),
            content_tag(:button, "Réinitialiser les filtres", class: "btn btn-primary")
          ])
        end
      end
    end
  end
  
  # @label Loading State
  def loading
    render Ui::DataGridComponent.new(data: [], loading: true) do |grid|
      grid.with_column(key: :name, label: "Nom")
      grid.with_column(key: :email, label: "Email")
      grid.with_column(key: :status, label: "Statut")
      grid.with_column(key: :created_at, label: "Date")
    end
  end
  
  # @label Compact Mode
  def compact
    data = sample_data(10)
    
    render Ui::DataGridComponent.new(data: data, compact: true) do |grid|
      grid.with_column(key: :name, label: "Nom")
      grid.with_column(key: :email, label: "Email")
      grid.with_column(key: :status, label: "Statut")
    end
  end
  
  # @label Complex Example
  def complex_example
    data = complex_data
    
    render Ui::DataGridComponent.new(
      data: data,
      striped: true,
      hover: true,
      bordered: true,
      selectable: true
    ) do |grid|
      grid.with_column(key: :id, label: "ID", width: "w-16", align: :center)
      grid.with_column(key: :name, label: "Nom complet", sortable: true)
      grid.with_column(key: :role, label: "Rôle")
      grid.with_column(key: :department, label: "Service")
      grid.with_column(key: :salary, label: "Salaire", format: :currency, align: :right)
      grid.with_column(key: :performance, label: "Performance", format: :percentage, align: :center)
      grid.with_column(key: :is_active, label: "Actif", format: :boolean, align: :center)
      grid.with_column(key: :hired_date, label: "Date embauche", format: :date)
      
      grid.configure_actions(style: :dropdown, dropdown_label: "Options")
      grid.with_action(label: "Voir profil", path: ->(item) { "#profile-#{item[:id]}" })
      grid.with_action(label: "Évaluation", path: ->(item) { "#review-#{item[:id]}" })
      grid.with_action(label: "Historique", path: ->(item) { "#history-#{item[:id]}" })
      grid.with_action(label: "Modifier", path: ->(item) { "#edit-#{item[:id]}" })
      grid.with_action(
        label: "Désactiver", 
        path: ->(item) { "#deactivate-#{item[:id]}" },
        condition: ->(item) { item[:is_active] }
      )
      grid.with_action(
        label: "Activer",
        path: ->(item) { "#activate-#{item[:id]}" },
        condition: ->(item) { !item[:is_active] }
      )
    end
  end
  
  private
  
  def sample_data(count = 5)
    count.times.map do |i|
      {
        id: i + 1,
        name: Faker::Name.name,
        email: Faker::Internet.email,
        status: ["Active", "Inactive", "Pending"].sample,
        created_at: Faker::Date.between(from: 1.year.ago, to: Date.today)
      }
    end
  end
  
  def financial_data
    5.times.map do |i|
      {
        id: i + 1,
        product: Faker::Commerce.product_name,
        price: Faker::Commerce.price(range: 10..500),
        discount: rand(5..30) / 100.0,
        in_stock: [true, false].sample,
        last_sale: Faker::Date.between(from: 1.month.ago, to: Date.today),
        status: ["available", "low_stock", "out_of_stock"].sample
      }
    end
  end
  
  def complex_data
    departments = ["Développement", "Marketing", "Ventes", "RH", "Finance"]
    roles = ["Junior", "Senior", "Manager", "Directeur"]
    
    8.times.map do |i|
      {
        id: i + 1,
        name: Faker::Name.name,
        role: roles.sample,
        department: departments.sample,
        salary: Faker::Number.between(from: 30000, to: 120000),
        performance: rand(60..100) / 100.0,
        is_active: i < 6,
        hired_date: Faker::Date.between(from: 5.years.ago, to: Date.today)
      }
    end
  end
  
  def status_class(status)
    case status
    when "available"
      "px-2 py-1 text-xs font-medium bg-green-100 text-green-800 rounded-full"
    when "low_stock"
      "px-2 py-1 text-xs font-medium bg-yellow-100 text-yellow-800 rounded-full"
    when "out_of_stock"
      "px-2 py-1 text-xs font-medium bg-red-100 text-red-800 rounded-full"
    else
      "px-2 py-1 text-xs font-medium bg-gray-100 text-gray-800 rounded-full"
    end
  end
end