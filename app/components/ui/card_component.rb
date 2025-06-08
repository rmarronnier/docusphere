class Ui::CardComponent < ApplicationComponent
  renders_one :footer
  renders_one :actions
  renders_one :subtitle

  def initialize(title: nil, variant: nil, collapsible: false, loading: false, href: nil, clickable: false, classes: nil, **options)
    @title = title
    @variant = variant
    @collapsible = collapsible
    @loading = loading
    @href = href
    @clickable = clickable
    @custom_classes = classes
    @options = options
  end

  private

  attr_reader :title, :variant, :collapsible, :loading, :href, :clickable, :custom_classes, :options

  def classes
    css_classes = ["card"]
    css_classes << "card-#{variant}" if variant
    css_classes << "card-clickable" if clickable
    css_classes << "card-loading" if loading
    css_classes << custom_classes if custom_classes
    css_classes.compact.join(" ")
  end

  def with_header?
    title.present? || subtitle?
  end

  def card_attributes
    attrs = { class: classes }
    attrs["data-controller"] = "collapse" if collapsible
    attrs
  end

  def content_attributes
    attrs = { class: "card-body" }
    attrs["data-collapse-target"] = "content" if collapsible
    attrs
  end
end