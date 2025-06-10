# Concern for handling component localization
module Localizable
  extend ActiveSupport::Concern

  included do
    # i18n helpers are available through ViewComponent
    # No need to delegate as they're already included
  end

  # Get component-specific translation
  def component_t(key, **options)
    scope = self.class.name.underscore.gsub('_component', '').gsub('/', '.')
    I18n.t("components.#{scope}.#{key}", **options)
  end

  # Check if translation exists
  def translation_exists?(key)
    scope = self.class.name.underscore.gsub('_component', '').gsub('/', '.')
    I18n.exists?("components.#{scope}.#{key}")
  end

  # Get label with fallback
  def label_with_fallback(key, fallback = nil)
    if translation_exists?(key)
      component_t(key)
    else
      fallback || key.to_s.humanize
    end
  end

  class_methods do
    # Define translatable attributes
    def translatable_attributes(*attrs)
      attrs.each do |attr|
        define_method "#{attr}_label" do
          value = instance_variable_get("@#{attr}")
          return nil unless value
          
          if translation_exists?("#{attr}.#{value}")
            component_t("#{attr}.#{value}")
          else
            value.to_s.humanize
          end
        end
      end
    end
  end
end