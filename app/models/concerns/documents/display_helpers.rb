# frozen_string_literal: true

module Documents
  module DisplayHelpers
    extend ActiveSupport::Concern

    # Display name for the document
    def display_name
      title
    end

    # Get full path including folder hierarchy
    def full_path
      return "/#{title}" unless folder
      "#{folder.full_path}/#{title}"
    end

    # Build breadcrumb items for navigation
    def breadcrumb_items
      items = []
      items << { name: space.name, path: space }
      
      if folder
        folder.ancestors.each do |ancestor|
          items << { name: ancestor.name, path: ancestor }
        end
        items << { name: folder.name, path: folder }
      end
      
      items << { name: title, path: self }
      items
    end
  end
end