# @label Stat Card Component
class Ui::StatCardComponentPreview < Lookbook::Preview
  layout "application"
  
  # @label Default Stat Card
  def default
    render Ui::StatCardComponent.new(
      title: "Total Documents",
      value: "1,234",
      icon: "document"
    )
  end
  
  # @label Multiple Stats
  def multiple_stats
    content_tag :div, class: "grid grid-cols-2 md:grid-cols-4 gap-4" do
      [
        render(Ui::StatCardComponent.new(
          title: "Documents",
          value: "1,234",
          icon: "document",
          trend: "+12%"
        )),
        render(Ui::StatCardComponent.new(
          title: "Utilisateurs",
          value: "89",
          icon: "user",
          trend: "+5%"
        )),
        render(Ui::StatCardComponent.new(
          title: "Espaces",
          value: "23",
          icon: "folder",
          trend: "+2%"
        )),
        render(Ui::StatCardComponent.new(
          title: "Taille",
          value: "2.4 GB",
          icon: "storage",
          trend: "+8%"
        ))
      ].join.html_safe
    end
  end
  
  # @label With Trends
  def with_trends
    content_tag :div, class: "grid grid-cols-3 gap-4" do
      [
        render(Ui::StatCardComponent.new(
          title: "Revenus",
          value: "€45,230",
          icon: "chart",
          trend: "+12.5%",
          trend_positive: true
        )),
        render(Ui::StatCardComponent.new(
          title: "Coûts",
          value: "€12,840",
          icon: "chart",
          trend: "-3.2%",
          trend_positive: false
        )),
        render(Ui::StatCardComponent.new(
          title: "Bénéfice",
          value: "€32,390",
          icon: "chart",
          trend: "+8.1%",
          trend_positive: true
        ))
      ].join.html_safe
    end
  end
  
  # @label Different Variants
  def variants
    content_tag :div, class: "grid grid-cols-2 gap-4" do
      [
        render(Ui::StatCardComponent.new(
          title: "Documents Actifs",
          value: "856",
          icon: "document",
          variant: "primary"
        )),
        render(Ui::StatCardComponent.new(
          title: "En Attente",
          value: "24",
          icon: "clock",
          variant: "warning"
        )),
        render(Ui::StatCardComponent.new(
          title: "Traités",
          value: "1,203",
          icon: "check",
          variant: "success"
        )),
        render(Ui::StatCardComponent.new(
          title: "Erreurs",
          value: "5",
          icon: "alert",
          variant: "danger"
        ))
      ].join.html_safe
    end
  end
end