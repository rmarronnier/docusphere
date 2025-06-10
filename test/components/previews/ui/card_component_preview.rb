# @label Card Component
class Ui::CardComponentPreview < Lookbook::Preview
  layout "application"
  
  # @label Default Card
  def default
    render Ui::CardComponent.new(title: "Titre de la carte") do
      content_tag :p, "Contenu de la carte. Lorem ipsum dolor sit amet, consectetur adipiscing elit."
    end
  end
  
  # @label With Footer
  def with_footer
    render Ui::CardComponent.new(title: "Carte avec footer") do |card|
      card.with_body do
        content_tag :p, "Contenu principal de la carte."
      end
      
      card.with_footer do
        content_tag :div, class: "flex justify-between items-center" do
          safe_join([
            content_tag(:span, "Dernière mise à jour : il y a 5 minutes", class: "text-sm text-gray-500"),
            content_tag(:button, "Action", class: "btn btn-sm btn-primary")
          ])
        end
      end
    end
  end
  
  # @label Padded Variations
  def padding_variations
    content_tag :div, class: "space-y-4" do
      safe_join([
        render(Ui::CardComponent.new(title: "Padding normal (par défaut)", padded: true)) { "Contenu avec padding normal" },
        render(Ui::CardComponent.new(title: "Sans padding", padded: false)) { "Contenu sans padding" }
      ])
    end
  end
  
  # @label Without Title
  def without_title
    render Ui::CardComponent.new do
      content_tag :div, class: "p-4" do
        safe_join([
          content_tag(:h3, "Contenu personnalisé", class: "text-lg font-medium mb-2"),
          content_tag(:p, "Une carte sans titre peut contenir n'importe quel contenu.")
        ])
      end
    end
  end
  
  # @label Complex Card
  def complex_example
    render Ui::CardComponent.new(title: "Statistiques du projet") do |card|
      card.with_body do
        content_tag :div, class: "space-y-4" do
          safe_join([
            # Stats grid
            content_tag(:div, class: "grid grid-cols-3 gap-4") do
              safe_join([
                stat_item("Documents", "1,234", "+12%"),
                stat_item("Utilisateurs", "456", "+5%"),
                stat_item("Espaces", "78", "+2%")
              ])
            end,
            
            # Chart placeholder
            content_tag(:div, class: "h-48 bg-gray-100 rounded flex items-center justify-center") do
              content_tag(:span, "Graphique", class: "text-gray-500")
            end
          ])
        end
      end
      
      card.with_footer do
        content_tag :div, class: "flex justify-between items-center" do
          safe_join([
            link_to("Voir le rapport complet", "#", class: "text-sm text-blue-600 hover:text-blue-800"),
            content_tag(:span, "Mis à jour: #{Time.current.strftime('%d/%m/%Y %H:%M')}", class: "text-sm text-gray-500")
          ])
        end
      end
    end
  end
  
  private
  
  def stat_item(label, value, change)
    content_tag :div, class: "text-center" do
      safe_join([
        content_tag(:p, label, class: "text-sm text-gray-500"),
        content_tag(:p, value, class: "text-2xl font-bold"),
        content_tag(:p, change, class: "text-sm #{change.start_with?('+') ? 'text-green-600' : 'text-red-600'}")
      ])
    end
  end
end