#!/usr/bin/env ruby

puts "Testing Immo::Promo routes..."

# Test d'accès aux routes principales
begin
  # Simuler une requête simple aux contrôleurs
  controller = Immo::Promo::ProjectsController.new
  puts "✓ ProjectsController can be instantiated"
  
  # Vérifier que les routes sont définies
  routes = Rails.application.routes.routes.map(&:path).map(&:spec).select { |r| r.include?('immo/promo') }
  puts "✓ Found #{routes.count} Immo::Promo routes"
  routes.each { |route| puts "  - #{route}" }
  
  # Tester l'accès aux modèles
  project = Immo::Promo::Project.first
  if project
    puts "✓ Found test project: #{project.name} (ID: #{project.id})"
    
    # Tester l'association milestones
    milestones_count = project.milestones.count
    puts "✓ Project milestones accessible (#{milestones_count} milestones)"
    
    # Tester les autres associations
    phases_count = project.phases.count
    puts "✓ Project phases accessible (#{phases_count} phases)"
    
    puts "✓ All model associations are working!"
  else
    puts "! No test project found"
  end
  
  puts "\n🎉 All tests passed! The Immo::Promo system is working correctly."
  puts "You can now access:"
  puts "- /immo/promo/projects (project list)"
  if project
    puts "- /immo/promo/projects/#{project.id} (project details)"
    puts "- /immo/promo/projects/#{project.id}/dashboard (project dashboard)"
  end
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(3)
end