module Concerns::Accessible
  extend ActiveSupport::Concern

  included do
    # Helper methods for ARIA attributes
    def aria_attributes(options = {})
      attrs = {}
      
      # Common ARIA attributes
      attrs["aria-label"] = options[:aria_label] if options[:aria_label]
      attrs["aria-labelledby"] = options[:aria_labelledby] if options[:aria_labelledby]
      attrs["aria-describedby"] = options[:aria_describedby] if options[:aria_describedby]
      attrs["aria-hidden"] = options[:aria_hidden] if options.key?(:aria_hidden)
      attrs["aria-live"] = options[:aria_live] if options[:aria_live]
      attrs["aria-atomic"] = options[:aria_atomic] if options.key?(:aria_atomic)
      attrs["aria-busy"] = options[:aria_busy] if options.key?(:aria_busy)
      attrs["aria-controls"] = options[:aria_controls] if options[:aria_controls]
      attrs["aria-current"] = options[:aria_current] if options[:aria_current]
      attrs["aria-disabled"] = options[:aria_disabled] if options.key?(:aria_disabled)
      attrs["aria-expanded"] = options[:aria_expanded] if options.key?(:aria_expanded)
      attrs["aria-haspopup"] = options[:aria_haspopup] if options[:aria_haspopup]
      attrs["aria-invalid"] = options[:aria_invalid] if options.key?(:aria_invalid)
      attrs["aria-pressed"] = options[:aria_pressed] if options.key?(:aria_pressed)
      attrs["aria-selected"] = options[:aria_selected] if options.key?(:aria_selected)
      attrs["aria-sort"] = options[:aria_sort] if options[:aria_sort]
      attrs["aria-valuemax"] = options[:aria_valuemax] if options[:aria_valuemax]
      attrs["aria-valuemin"] = options[:aria_valuemin] if options[:aria_valuemin]
      attrs["aria-valuenow"] = options[:aria_valuenow] if options[:aria_valuenow]
      attrs["aria-valuetext"] = options[:aria_valuetext] if options[:aria_valuetext]
      
      attrs
    end

    # Generate appropriate role attribute
    def role_attribute(element_type, options = {})
      return options[:role] if options[:role]
      
      case element_type
      when :nav, :navigation
        "navigation"
      when :banner
        "banner"
      when :main
        "main"
      when :complementary, :aside
        "complementary"
      when :contentinfo, :footer
        "contentinfo"
      when :search
        "search"
      when :form
        "form"
      when :region
        "region"
      when :alert
        "alert"
      when :alertdialog
        "alertdialog"
      when :button
        "button"
      when :checkbox
        "checkbox"
      when :dialog
        "dialog"
      when :grid
        "grid"
      when :group
        "group"
      when :heading
        "heading"
      when :img
        "img"
      when :link
        "link"
      when :list
        "list"
      when :listbox
        "listbox"
      when :listitem
        "listitem"
      when :menu
        "menu"
      when :menubar
        "menubar"
      when :menuitem
        "menuitem"
      when :menuitemcheckbox
        "menuitemcheckbox"
      when :menuitemradio
        "menuitemradio"
      when :option
        "option"
      when :progressbar
        "progressbar"
      when :radio
        "radio"
      when :radiogroup
        "radiogroup"
      when :region
        "region"
      when :separator
        "separator"
      when :slider
        "slider"
      when :spinbutton
        "spinbutton"
      when :status
        "status"
      when :switch
        "switch"
      when :tab
        "tab"
      when :tablist
        "tablist"
      when :tabpanel
        "tabpanel"
      when :textbox
        "textbox"
      when :toolbar
        "toolbar"
      when :tooltip
        "tooltip"
      when :tree
        "tree"
      when :treeitem
        "treeitem"
      else
        nil
      end
    end

    # Focus management helpers
    def focus_classes(options = {})
      classes = []
      
      # Default focus styles
      classes << "focus:outline-none"
      classes << "focus-visible:ring-2"
      classes << "focus-visible:ring-offset-2"
      
      # Color customization
      color = options[:focus_color] || "primary"
      classes << "focus-visible:ring-#{color}-500"
      
      # Size customization
      case options[:focus_size]
      when :sm
        classes << "focus-visible:ring-1"
      when :lg
        classes << "focus-visible:ring-4"
      else
        classes << "focus-visible:ring-2"
      end
      
      classes.join(" ")
    end

    # Screen reader only text
    def sr_only(text)
      content_tag(:span, text, class: "sr-only")
    end

    # Skip links for keyboard navigation
    def skip_link(target, text = "Skip to main content")
      link_to text, target, 
              class: "sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 bg-white px-4 py-2 rounded-md shadow-lg z-50"
    end

    # Keyboard navigation helpers
    def keyboard_navigable_attributes(options = {})
      attrs = {}
      
      # Tabindex
      attrs[:tabindex] = options[:tabindex] if options.key?(:tabindex)
      
      # Keyboard shortcuts
      attrs["data-keyboard-shortcut"] = options[:keyboard_shortcut] if options[:keyboard_shortcut]
      
      attrs
    end

    # Color contrast helpers
    def contrast_safe_color(background_color, light_color = "white", dark_color = "gray-900")
      # This is a simplified version - in production, you'd calculate actual contrast ratios
      case background_color
      when /gray-[89]|black|primary-[789]|blue-[789]|green-[789]|red-[789]/
        "text-#{light_color}"
      else
        "text-#{dark_color}"
      end
    end

    # Announce changes to screen readers
    def live_region(content, politeness = :polite, atomic = true)
      content_tag(:div, content,
                  role: "status",
                  "aria-live": politeness,
                  "aria-atomic": atomic,
                  class: "sr-only")
    end
  end
end