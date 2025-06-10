# @label User Avatar Component
class Ui::UserAvatarComponentPreview < Lookbook::Preview
  layout "application"
  
  # @label Default Avatar
  def default
    render Ui::UserAvatarComponent.new(name: "Jean Dupont")
  end
  
  # @label Avatar with Image
  def with_image
    render Ui::UserAvatarComponent.new(
      name: "Marie Martin", 
      image_url: "https://ui-avatars.com/api/?name=Marie+Martin&background=3b82f6&color=fff"
    )
  end
  
  # @label Different Sizes
  def sizes
    content_tag :div, class: "flex items-center space-x-6" do
      [
        content_tag(:div, class: "text-center") do
          [
            render(Ui::UserAvatarComponent.new(name: "John Doe", size: "sm")),
            content_tag(:div, "Small", class: "mt-2 text-sm")
          ].join.html_safe
        end,
        content_tag(:div, class: "text-center") do
          [
            render(Ui::UserAvatarComponent.new(name: "Jane Smith", size: "md")),
            content_tag(:div, "Medium", class: "mt-2 text-sm")
          ].join.html_safe
        end,
        content_tag(:div, class: "text-center") do
          [
            render(Ui::UserAvatarComponent.new(name: "Bob Wilson", size: "lg")),
            content_tag(:div, "Large", class: "mt-2 text-sm")
          ].join.html_safe
        end,
        content_tag(:div, class: "text-center") do
          [
            render(Ui::UserAvatarComponent.new(name: "Alice Brown", size: "xl")),
            content_tag(:div, "Extra Large", class: "mt-2 text-sm")
          ].join.html_safe
        end
      ].join.html_safe
    end
  end
  
  # @label Multiple Users
  def multiple_users
    users = [
      { name: "Alice Dubois", role: "Architecte" },
      { name: "Bob Martin", role: "Chef de projet" },
      { name: "Claire Bernard", role: "Développeuse" },
      { name: "David Moreau", role: "Designer" }
    ]
    
    content_tag :div, class: "space-y-4" do
      users.map do |user|
        content_tag(:div, class: "flex items-center space-x-3 p-3 border rounded-lg") do
          [
            render(Ui::UserAvatarComponent.new(name: user[:name], size: "md")),
            content_tag(:div) do
              [
                content_tag(:div, user[:name], class: "font-medium"),
                content_tag(:div, user[:role], class: "text-sm text-gray-600")
              ].join.html_safe
            end
          ].join.html_safe
        end
      end.join.html_safe
    end
  end
  
  # @label Avatar Group
  def avatar_group
    names = ["Alice A.", "Bob B.", "Charlie C.", "Diana D.", "Eve E."]
    
    content_tag :div, class: "flex -space-x-2" do
      names.map.with_index do |name, index|
        content_tag(:div, 
          render(Ui::UserAvatarComponent.new(name: name, size: "md")),
          class: "relative z-#{30 - index * 5} border-2 border-white rounded-full"
        )
      end.join.html_safe
    end
  end
end