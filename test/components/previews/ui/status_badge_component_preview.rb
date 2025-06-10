# @label Status Badge Component
class Ui::StatusBadgeComponentPreview < Lookbook::Preview
  layout "application"
  
  # @label Default Status Badge
  def default
    render Ui::StatusBadgeComponent.new(status: "active")
  end
  
  # @label All Status Types
  def all_statuses
    content_tag :div, class: "space-y-4" do
      [
        content_tag(:div, class: "space-x-2") do
          [
            render(Ui::StatusBadgeComponent.new(status: :active)),
            render(Ui::StatusBadgeComponent.new(status: :inactive)),
            render(Ui::StatusBadgeComponent.new(status: :pending)),
            render(Ui::StatusBadgeComponent.new(status: :completed)),
            render(Ui::StatusBadgeComponent.new(status: :in_progress)),
            render(Ui::StatusBadgeComponent.new(status: :delayed))
          ].map(&:to_s).join.html_safe
        end,
        content_tag(:h3, "Statuts de document", class: "text-lg font-semibold mt-6"),
        content_tag(:div, class: "space-x-2") do
          [
            render(Ui::StatusBadgeComponent.new(status: :published)),
            render(Ui::StatusBadgeComponent.new(status: :draft)),
            render(Ui::StatusBadgeComponent.new(status: :archived))
          ].map(&:to_s).join.html_safe
        end
      ].join.html_safe
    end
  end
  
  # @label Different Sizes
  def small_badges
    content_tag :div, class: "space-x-2" do
      [
        render(Ui::StatusBadgeComponent.new(status: :active, size: :small)),
        render(Ui::StatusBadgeComponent.new(status: :pending, size: :medium)),
        render(Ui::StatusBadgeComponent.new(status: :delayed, size: :large))
      ].join.html_safe
    end
  end
end