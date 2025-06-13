module Immo
  module Promo
    module Shared
      class HeaderCardComponent < ApplicationComponent
        def initialize(
          title:,
          subtitle: nil,
          actions: [],
          size: :large,
          show_background: true,
          background_color: 'bg-white',
          shadow: true,
          padding: 'p-6',
          border_radius: 'rounded-lg',
          extra_classes: nil
        )
          @title = title
          @subtitle = subtitle
          @actions = actions.nil? ? [] : (actions.is_a?(Array) ? actions : [actions])
          @size = size.to_sym
          @show_background = show_background
          @background_color = background_color
          @shadow = shadow
          @padding = padding
          @border_radius = border_radius
          @extra_classes = extra_classes
        end

        private

        attr_reader :title, :subtitle, :actions, :size, :show_background, :background_color,
                    :shadow, :padding, :border_radius, :extra_classes

        def header_classes
          classes = []
          
          if show_background
            classes << background_color
            classes << 'shadow' if shadow
            classes << border_radius
            classes << padding
          end
          
          classes << extra_classes if extra_classes.present?
          classes.compact.join(' ')
        end

        def title_classes
          case size
          when :small
            'text-lg font-semibold leading-6 text-gray-900'
          when :medium
            'text-xl font-semibold leading-7 text-gray-900 sm:text-2xl'
          when :large
            'text-2xl font-bold leading-7 text-gray-900 sm:truncate sm:text-3xl sm:tracking-tight'
          when :extra_large
            'text-3xl font-bold leading-9 text-gray-900 sm:text-4xl sm:tracking-tight'
          else
            'text-2xl font-bold leading-7 text-gray-900 sm:truncate sm:text-3xl sm:tracking-tight'
          end
        end

        def subtitle_classes
          case size
          when :small
            'text-sm text-gray-500'
          when :medium, :large, :extra_large
            'mt-1 text-sm text-gray-500'
          else
            'mt-1 text-sm text-gray-500'
          end
        end

        def has_actions?
          actions.present? && actions.any?
        end

        def actions_container_classes
          'mt-4 flex flex-wrap gap-3 md:ml-4 md:mt-0'
        end

        def main_container_classes
          'md:flex md:items-center md:justify-between'
        end

        def content_container_classes
          'min-w-0 flex-1'
        end

        # Helper to render actions
        def render_action(action)
          case action
          when Hash
            render_hash_action(action)
          when String
            content_tag(:div, action.html_safe, class: 'inline-flex')
          else
            content_tag(:div, action.to_s, class: 'inline-flex')
          end
        end

        def render_hash_action(action)
          # Default button classes for consistency
          default_classes = 'inline-flex items-center rounded-md px-3 py-2 text-sm font-semibold shadow-sm'
          
          # Handle different action types
          if action[:type] == :primary
            button_classes = "#{default_classes} bg-indigo-600 text-white hover:bg-indigo-500"
          elsif action[:type] == :secondary
            button_classes = "#{default_classes} bg-white text-gray-900 ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
          else
            button_classes = "#{default_classes} #{action[:class] || 'bg-white text-gray-900 ring-1 ring-inset ring-gray-300 hover:bg-gray-50'}"
          end

          # Add any extra classes specified
          button_classes = "#{button_classes} #{action[:extra_classes]}".strip if action[:extra_classes]

          # Handle different action formats
          if action[:href]
            # Link action
            link_to(action[:text] || action[:label], action[:href], 
                   class: button_classes,
                   **action.except(:text, :label, :href, :type, :class, :extra_classes))
          elsif action[:method] || action[:url]
            # Button with form methods or URL
            options = {
              method: action[:method] || :post,
              class: button_classes,
              form: {}
            }
            
            # Add data attributes to the form
            if action[:data]
              options[:form][:data] = action[:data]
            end
            
            # Add any additional attributes
            action.except(:text, :label, :url, :method, :type, :class, :extra_classes, :data).each do |key, value|
              options[key] = value
            end
            
            button_to(action[:text] || action[:label], action[:url], options)
          elsif action[:html]
            # Raw HTML action
            action[:html].html_safe
          else
            # Simple button (including data attributes without URL)
            button_options = {
              class: button_classes,
              type: action[:button_type] || 'button'
            }
            
            # Add data attributes if present
            button_options[:data] = action[:data] if action[:data]
            
            # Add any additional attributes
            action.except(:text, :label, :type, :class, :extra_classes, :button_type, :data).each do |key, value|
              button_options[key] = value
            end
            
            content_tag(:button, action[:text] || action[:label], button_options)
          end
        end
      end
    end
  end
end