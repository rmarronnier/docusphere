class Ui::DataGridComponent::EmptyStateComponent < ApplicationComponent
  attr_reader :message, :icon, :show_icon, :custom_content

  def initialize(
    message: "Aucune donnée disponible",
    icon: "document",
    show_icon: true,
    custom_content: nil
  )
    @message = message
    @icon = icon
    @show_icon = show_icon
    @custom_content = custom_content
  end

  def call
    if custom_content
      # If custom content is provided, render it directly
      custom_content
    else
      # Otherwise, render the default empty state
      content_tag :div, class: "text-center py-12" do
        safe_join([
          show_icon ? render_icon : nil,
          content_tag(:p, message, class: "mt-2 text-sm text-gray-500")
        ].compact)
      end
    end
  end

  private

  def render_icon
    content_tag :div, class: "mx-auto h-12 w-12 text-gray-400" do
      icon_svg(icon)
    end
  end

  def icon_svg(name)
    case name
    when "document"
      content_tag :svg, class: "h-12 w-12", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor" do
        tag :path, "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2",
            d: "M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
      end
    when "folder"
      content_tag :svg, class: "h-12 w-12", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor" do
        tag :path, "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2",
            d: "M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z"
      end
    when "search"
      content_tag :svg, class: "h-12 w-12", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor" do
        tag :path, "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2",
            d: "M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
      end
    when "inbox"
      content_tag :svg, class: "h-12 w-12", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor" do
        tag :path, "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2",
            d: "M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"
      end
    when "users"
      content_tag :svg, class: "h-12 w-12", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor" do
        tag :path, "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2",
            d: "M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"
      end
    else
      # Default/generic empty icon
      content_tag :svg, class: "h-12 w-12", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor" do
        tag :path, "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2",
            d: "M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"
      end
    end
  end
end