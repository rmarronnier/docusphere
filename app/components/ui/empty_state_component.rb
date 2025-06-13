class Ui::EmptyStateComponent < ApplicationComponent
  def initialize(title:, description: nil, icon: nil, action_text: nil, action_onclick: nil, action_href: nil, action_classes: nil)
    @title = title
    @description = description
    @icon = icon
    @action_text = action_text
    @action_onclick = action_onclick
    @action_href = action_href
    @action_classes = action_classes
  end

  private

  attr_reader :title, :description, :icon, :action_text, :action_onclick, :action_href, :action_classes
  
  def default_icon
    '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>'
  end
end