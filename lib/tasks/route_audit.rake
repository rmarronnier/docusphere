namespace :routes do
  desc "Audit route helpers usage in views and components"
  task audit: :environment do
    puts "🔍 Auditing route helpers usage...\n\n"
    
    # 1. Trouver tous les helpers utilisés dans les vues
    view_files = Dir[Rails.root.join('app/views/**/*.erb')] + 
                 Dir[Rails.root.join('app/components/**/*.erb')]
    
    helpers_used = Set.new
    hardcoded_paths = []
    component_issues = []
    
    view_files.each do |file|
      content = File.read(file)
      relative_path = file.gsub(Rails.root.to_s + '/', '')
      
      # Extraire les helpers de routes
      route_patterns = content.scan(/(\w+_(?:path|url))\b/)
      helpers_used.merge(route_patterns.flatten)
      
      # Détecter les chemins hardcodés
      hardcoded_patterns = [
        /href=["']\/[^"'#]*["']/,
        /link_to\s+["']\/[^"'#]*["']/,
        /action=["']\/[^"'#]*["']/
      ]
      
      hardcoded_patterns.each do |pattern|
        matches = content.scan(pattern)
        if matches.any?
          hardcoded_paths << {
            file: relative_path,
            matches: matches.flatten
          }
        end
      end
      
      # Vérifier l'usage dans les ViewComponents
      if relative_path.include?('app/components/')
        # Détecter l'usage direct de route helpers (sans helpers.)
        direct_usage = content.scan(/(?<!helpers\.)\b(\w+_(?:path|url))\b/)
        if direct_usage.any?
          # Filtrer les cas légitimes (data attributes)
          problematic = direct_usage.flatten.reject do |helper|
            content.match?(/data-[\w-]+-url-value=.*#{Regexp.escape(helper)}/)
          end
          
          if problematic.any?
            component_issues << {
              file: relative_path,
              helpers: problematic
            }
          end
        end
      end
    end
    
    # 2. Vérifier que les helpers existent
    available_helpers = Rails.application.routes.url_helpers.methods
    missing_helpers = []
    
    helpers_used.each do |helper|
      # Ignorer les helpers spéciaux Rails
      next if ['root_path', 'root_url', 'rails_blob_path', 'rails_blob_url'].include?(helper)
      next if helper.match(/^rails_/)
      
      unless available_helpers.include?(helper.to_sym)
        missing_helpers << helper
      end
    end
    
    # 3. Rapport des résultats
    puts "📊 ROUTE AUDIT RESULTS"
    puts "=" * 50
    
    if missing_helpers.any?
      puts "❌ MISSING ROUTE HELPERS (#{missing_helpers.count}):"
      missing_helpers.sort.each do |helper|
        puts "   • #{helper}"
      end
      puts
    else
      puts "✅ All route helpers exist!"
      puts
    end
    
    if hardcoded_paths.any?
      puts "⚠️  HARDCODED PATHS FOUND (#{hardcoded_paths.count} files):"
      hardcoded_paths.each do |item|
        puts "   📁 #{item[:file]}"
        item[:matches].each do |match|
          puts "      → #{match}"
        end
      end
      puts
    else
      puts "✅ No hardcoded paths found!"
      puts
    end
    
    if component_issues.any?
      puts "🔧 VIEWCOMPONENT ROUTE HELPER ISSUES (#{component_issues.count} files):"
      component_issues.each do |item|
        puts "   📁 #{item[:file]}"
        item[:helpers].each do |helper|
          puts "      → #{helper} (should use helpers.#{helper})"
        end
      end
      puts
    else
      puts "✅ ViewComponent route helper usage is correct!"
      puts
    end
    
    # 4. Recommandations
    puts "💡 RECOMMENDATIONS:"
    puts "=" * 50
    
    if missing_helpers.any?
      puts "1. Fix missing route helpers:"
      puts "   - Check routes.rb for typos"
      puts "   - Add missing routes or update view references"
      puts
    end
    
    if hardcoded_paths.any?
      puts "2. Replace hardcoded paths with route helpers:"
      puts "   - Use xxx_path helpers instead of '/xxx'"
      puts "   - Enables URL changes without breaking views"
      puts
    end
    
    if component_issues.any?
      puts "3. Fix ViewComponent route helper usage:"
      puts "   - Use helpers.xxx_path in ViewComponent templates"
      puts "   - Direct xxx_path calls may not work in component context"
      puts
    end
    
    puts "Run: rake routes:fix_common_issues to auto-fix common problems"
    puts
  end
  
  desc "Fix common route issues automatically"
  task fix_common_issues: :environment do
    puts "🔧 Fixing common route issues...\n\n"
    
    fixes_applied = 0
    
    # Corriger les problèmes dans les ViewComponents
    component_files = Dir[Rails.root.join('app/components/**/*.erb')]
    
    component_files.each do |file|
      content = File.read(file)
      original_content = content.dup
      relative_path = file.gsub(Rails.root.to_s + '/', '')
      
      # Remplacer les appels directs par helpers.xxx_path
      # Mais éviter les data attributes
      content.gsub!(/\b(\w+_(?:path|url))\b/) do |match|
        # Vérifier le contexte - ne pas remplacer si déjà avec helpers ou dans data attributes
        before_match = $`[-50..-1] || $`
        
        # Ne pas remplacer si déjà avec helpers.
        next match if before_match.end_with?('helpers.')
        
        # Ne pas remplacer dans les data attributes
        if before_match.match?(/data-[\w-]+-[\w-]*url[\w-]*=["'][^"']*\z/)
          match # Garder tel quel
        else
          "helpers.#{match}"
        end
      end
      
      if content != original_content
        File.write(file, content)
        puts "✅ Fixed ViewComponent route helpers in #{relative_path}"
        fixes_applied += 1
      end
    end
    
    puts "\n🎉 Applied #{fixes_applied} fixes!"
    puts "Run 'rake routes:audit' to verify remaining issues."
  end
  
  desc "Generate route helper validation test"
  task generate_validation_test: :environment do
    puts "📝 Generating route validation test...\n\n"
    
    # Collecter tous les helpers utilisés
    view_files = Dir[Rails.root.join('app/views/**/*.erb')] + 
                 Dir[Rails.root.join('app/components/**/*.erb')]
    
    helpers_used = Set.new
    
    view_files.each do |file|
      content = File.read(file)
      route_patterns = content.scan(/(\w+_(?:path|url))\b/)
      helpers_used.merge(route_patterns.flatten)
    end
    
    # Filtrer et organiser
    app_helpers = helpers_used.reject { |h| h.match(/^rails_/) || ['root_path', 'root_url'].include?(h) }
    
    test_content = <<~RUBY
      # Generated by rake routes:generate_validation_test
      require 'rails_helper'
      
      RSpec.describe "Route Helpers Used in Application", type: :routing do
        it "validates all route helpers used in views exist" do
          helpers_to_test = #{app_helpers.sort.inspect}
          
          helpers_to_test.each do |helper|
            expect(Rails.application.routes.url_helpers).to respond_to(helper.to_sym),
                   "Route helper '\#{helper}' is used in views but doesn't exist"
          end
        end
      end
    RUBY
    
    File.write(Rails.root.join('spec/routing/generated_route_validation_spec.rb'), test_content)
    puts "✅ Generated spec/routing/generated_route_validation_spec.rb"
    puts "Run: bundle exec rspec spec/routing/generated_route_validation_spec.rb"
  end
end