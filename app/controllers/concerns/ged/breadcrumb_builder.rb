module Ged
  module BreadcrumbBuilder
    extend ActiveSupport::Concern

    private

    def build_folder_breadcrumbs(folder)
      breadcrumbs = [{ name: 'GED', path: ged_dashboard_path }]
      breadcrumbs << { name: folder.space.name, path: ged_space_path(folder.space) }
      
      # Build folder hierarchy
      folder_hierarchy = []
      current = folder
      while current
        folder_hierarchy.unshift(current)
        current = current.parent
      end
      
      folder_hierarchy.each do |f|
        breadcrumbs << { name: f.name, path: ged_folder_path(f) }
      end
      
      breadcrumbs
    end

    def build_document_breadcrumbs(document)
      breadcrumbs = [{ name: 'GED', path: ged_dashboard_path }]
      breadcrumbs << { name: document.space.name, path: ged_space_path(document.space) }
      
      if document.folder
        # Build folder hierarchy
        folder_hierarchy = []
        current = document.folder
        while current
          folder_hierarchy.unshift(current)
          current = current.parent
        end
        
        folder_hierarchy.each do |f|
          breadcrumbs << { name: f.name, path: ged_folder_path(f) }
        end
      end
      
      breadcrumbs << { name: document.title, path: ged_document_path(document) }
      breadcrumbs
    end
  end
end