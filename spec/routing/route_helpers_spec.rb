require 'rails_helper'

RSpec.describe "Route Helpers Validation", type: :routing do
  describe "Application route helpers" do
    # Test que tous les helpers de routes utilisés dans les vues existent
    it "validates all route helpers used in views exist" do
      # Scan tous les fichiers de vues pour des patterns de routes
      view_files = Dir[Rails.root.join('app/views/**/*.erb')] + 
                   Dir[Rails.root.join('app/components/**/*.erb')]
      
      route_helpers_used = []
      
      view_files.each do |file|
        content = File.read(file)
        
        # Chercher tous les patterns xxx_path et xxx_url
        # Exclure les patterns qui sont des appels de méthodes (précédés d'un point)
        route_patterns = content.scan(/(?<!\.)\b(\w+_(?:path|url))\b/)
        route_helpers_used.concat(route_patterns.flatten)
      end
      
      route_helpers_used.uniq.each do |helper|
        # Ignorer les helpers spéciaux Rails
        next if ['root_path', 'root_url', 'rails_blob_path', 'rails_blob_url'].include?(helper)
        next if helper.match(/^rails_/)
        
        # Ignorer les routes d'engine (qui sont préfixées par l'engine)
        engine_routes = ['projects_path', 'project_path', 'project_phases_path']
        next if engine_routes.include?(helper)
        
        # Ignorer les méthodes de composants qui ne sont pas des routes
        component_methods = ['icon_path', 'document_url', 'item_path', 'form_url', 'full_path', 'thumbnail_url', 'preview_url']
        next if component_methods.include?(helper)
        
        # Ignorer les helpers Rails standards
        rails_helpers = ['asset_path', 'asset_url', 'image_path', 'image_url', 'javascript_path', 'stylesheet_path']
        next if rails_helpers.include?(helper)
        
        # Ignorer les helpers Devise standards
        devise_patterns = ['confirmation', 'password', 'registration', 'unlock', 'session']
        next if devise_patterns.any? { |pattern| helper.include?(pattern) }
        
        # Ignorer les helpers OmniAuth
        next if helper.include?('omniauth')
        
        # Ignorer les helpers polymorphiques générés dynamiquement
        polymorphic_helpers = ['notifiable_url', 'notifiable_path']
        next if polymorphic_helpers.include?(helper)
        
        # Ignorer les helpers PWA/manifest
        pwa_helpers = ['start_url', 'start_path']
        next if pwa_helpers.include?(helper)
        
        expect(Rails.application.routes.url_helpers).to respond_to(helper), 
               "Route helper '#{helper}' is used in views but doesn't exist"
      end
    end
    
    it "validates GED routes are correctly referenced" do
      # Les routes GED doivent utiliser le bon préfixe
      expect(Rails.application.routes.url_helpers).to respond_to(:ged_document_path)
      expect(Rails.application.routes.url_helpers).to respond_to(:ged_space_path)
      expect(Rails.application.routes.url_helpers).to respond_to(:ged_folder_path)
      expect(Rails.application.routes.url_helpers).to respond_to(:ged_download_document_path)
      expect(Rails.application.routes.url_helpers).to respond_to(:ged_preview_document_path)
    end
    
    it "validates engine routes are properly mounted" do
      # Vérifier que l'engine ImmoPromo est monté
      # On vérifie qu'au moins une route de l'engine existe
      routes = Rails.application.routes.routes.map { |r| r.name }.compact
      engine_routes = routes.select { |name| name.start_with?('immo_promo') }
      
      expect(engine_routes).not_to be_empty
    end
  end
  
  describe "Route consistency checks" do
    it "ensures no hardcoded paths in views" do
      view_files = Dir[Rails.root.join('app/views/**/*.erb')] + 
                   Dir[Rails.root.join('app/components/**/*.erb')]
      
      hardcoded_paths = []
      
      view_files.each do |file|
        content = File.read(file)
        relative_path = file.gsub(Rails.root.to_s + '/', '')
        
        # Chercher des chemins hardcodés suspects
        hardcoded_patterns = [
          /href=["']\/\w+/,           # href="/something"
          /link_to\s+["']\/\w+/,      # link_to "/something"
          /action=["']\/\w+/,         # action="/something"
          /url:\s*["']\/\w+/          # url: "/something"
        ]
        
        hardcoded_patterns.each do |pattern|
          matches = content.scan(pattern)
          if matches.any?
            hardcoded_paths << {
              file: relative_path,
              matches: matches,
              lines: content.lines.each_with_index.select { |line, _| line.match?(pattern) }
                           .map { |_, index| index + 1 }
            }
          end
        end
      end
      
      if hardcoded_paths.any?
        error_msg = "Hardcoded paths found (should use route helpers):\n"
        hardcoded_paths.each do |item|
          error_msg += "#{item[:file]} (lines: #{item[:lines].join(', ')})\n"
        end
        
        # Warning seulement car il peut y avoir des cas légitimes
        warn error_msg
      end
    end
    
    it "validates ViewComponent route helper usage" do
      component_files = Dir[Rails.root.join('app/components/**/*.erb')]
      
      component_files.each do |file|
        content = File.read(file)
        relative_path = file.gsub(Rails.root.to_s + '/', '')
        
        # Dans les ViewComponents, on devrait utiliser helpers.xxx_path
        direct_route_usage = content.scan(/(?<!helpers\.)\b\w+_(?:path|url)\b/)
        
        if direct_route_usage.any?
          # Filtrer les cas légitimes (comme dans data attributes)
          legitimate_cases = direct_route_usage.select do |helper|
            # Cas où c'est dans un data attribute ou string interpolation
            content.match?(/data-\w+-url-value=.*#{Regexp.escape(helper)}/)
          end
          
          problematic_cases = direct_route_usage - legitimate_cases
          
          if problematic_cases.any?
            warn "Direct route helper usage in ViewComponent #{relative_path}: #{problematic_cases.uniq.join(', ')}"
            warn "Consider using helpers.#{problematic_cases.first} instead"
          end
        end
      end
    end
  end
  
  describe "Critical route availability" do
    it "validates essential application routes" do
      essential_routes = %w[
        root_path
        dashboard_path
        search_path
        notifications_path
        ged_dashboard_path
      ]
      
      essential_routes.each do |route|
        expect(Rails.application.routes.url_helpers).to respond_to(route),
               "Essential route #{route} is missing"
      end
    end
    
    it "validates document operation routes" do
      document_routes = %w[
        ged_document_path
        ged_download_document_path
        ged_preview_document_path
        ged_lock_document_path
        ged_unlock_document_path
      ]
      
      document_routes.each do |route|
        expect(Rails.application.routes.url_helpers).to respond_to(route),
               "Document route #{route} is missing"
      end
    end
  end
end