class Ui::CardComponent < ApplicationComponent
  def initialize(title: nil, **options)
    @title = title
    @options = options
  end

  private

  attr_reader :title, :options

  def classes
    ["card", options[:class]].compact.join(" ")
  end

  def with_header?
    title.present? || content_for?(:header)
  end
end