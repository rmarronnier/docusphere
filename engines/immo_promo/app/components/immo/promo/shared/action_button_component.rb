module Immo
  module Promo
    module Shared
      class ActionButtonComponent < ApplicationComponent
        def initialize(path:, text:, icon: nil, variant: 'primary', size: 'default', method: :get, confirm: nil, data: {}, classes: nil)
          @path = path
          @text = text
          @icon = icon
          @variant = variant
          @size = size
          @method = method
          @confirm = confirm
          @data = data
          @custom_classes = classes
        end

        private

        attr_reader :path, :text, :icon, :variant, :size, :method, :confirm, :data, :custom_classes

        def button_classes
          base_classes = 'inline-flex items-center justify-center font-medium rounded-md focus:outline-none focus:ring-2 focus:ring-offset-2 transition-colors'
          
          variant_classes = case variant
          when 'primary'
            'bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500'
          when 'secondary'
            'bg-white text-gray-700 border border-gray-300 hover:bg-gray-50 focus:ring-blue-500'
          when 'danger'
            'bg-red-600 text-white hover:bg-red-700 focus:ring-red-500'
          when 'warning'
            'bg-yellow-600 text-white hover:bg-yellow-700 focus:ring-yellow-500'
          when 'success'
            'bg-green-600 text-white hover:bg-green-700 focus:ring-green-500'
          when 'outline-primary'
            'border border-blue-600 text-blue-600 hover:bg-blue-50 focus:ring-blue-500'
          when 'outline-secondary'
            'border border-gray-300 text-gray-700 hover:bg-gray-50 focus:ring-gray-500'
          when 'outline-danger'
            'border border-red-600 text-red-600 hover:bg-red-50 focus:ring-red-500'
          else
            'bg-gray-600 text-white hover:bg-gray-700 focus:ring-gray-500'
          end
          
          size_classes = case size
          when 'small', 'sm'
            'px-3 py-1.5 text-sm'
          when 'large', 'lg'
            'px-6 py-3 text-base'
          else
            'px-4 py-2 text-sm'
          end
          
          [base_classes, variant_classes, size_classes, custom_classes].compact.join(' ')
        end

        def icon_classes
          case size
          when 'small', 'sm'
            'h-4 w-4'
          when 'large', 'lg'
            'h-6 w-6'
          else
            'h-5 w-5'
          end
        end

        def link_data
          link_data = data.dup
          link_data[:confirm] = confirm if confirm.present?
          link_data[:method] = method if method != :get
          link_data
        end
      end
    end
  end
end