class Layout::PageHeaderComponent < ApplicationComponent
  def initialize(title:, description: nil, show_actions: true)
    @title = title
    @description = description
    @show_actions = show_actions
  end

  private

  attr_reader :title, :description, :show_actions
end