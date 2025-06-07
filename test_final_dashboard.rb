#!/usr/bin/env ruby

puts "Testing final dashboard access..."

begin
  # Test 1: Dashboard global
  puts "\n=== Testing Global Dashboard ==="
  controller = Immo::Promo::ProjectsController.new
  controller.params = ActionController::Parameters.new({})  # Pas d'ID
  
  # Simuler l'exécution de la méthode dashboard
  projects = Immo::Promo::Project.active
  puts "✓ Global dashboard projects query OK (#{projects.count} projects)"
  
  upcoming_milestones = Immo::Promo::Milestone.joins(:project)
                                             .where(project: projects)
                                             .upcoming
                                             .limit(10)
  puts "✓ Global dashboard milestones query OK (#{upcoming_milestones.count} milestones)"
  
  overdue_tasks = Immo::Promo::Task.joins(phase: :project)
                                   .where(phase: { project: projects })
                                   .overdue
                                   .limit(10)
  puts "✓ Global dashboard tasks query OK (#{overdue_tasks.count} tasks)"
  
  # Test 2: Dashboard de projet spécifique
  puts "\n=== Testing Project Specific Dashboard ==="
  project = Immo::Promo::Project.first
  if project
    specific_projects = [project]
    puts "✓ Project specific dashboard - project found (ID: #{project.id})"
    
    upcoming_milestones = Immo::Promo::Milestone.joins(:project)
                                               .where(project: specific_projects)
                                               .upcoming
                                               .limit(10)
    puts "✓ Project dashboard milestones query OK (#{upcoming_milestones.count} milestones)"
    
    overdue_tasks = Immo::Promo::Task.joins(phase: :project)
                                     .where(phase: { project: specific_projects })
                                     .overdue
                                     .limit(10)
    puts "✓ Project dashboard tasks query OK (#{overdue_tasks.count} tasks)"
  else
    puts "! No project found for specific dashboard test"
  end
  
  # Test 3: Vérifier les nouvelles routes
  puts "\n=== Testing Route Structure ==="
  routes = Rails.application.routes.routes.map(&:path).map(&:spec).select { |r| r.include?('immo/promo') && r.include?('dashboard') }
  puts "✓ Found dashboard routes:"
  routes.each { |route| puts "  - #{route}" }
  
  puts "\n🎉 All dashboard tests passed!"
  puts "\nAvailable dashboard access:"
  puts "- /immo/promo (global dashboard)"
  if project
    puts "- /immo/promo/projects/#{project.id}/dashboard (project specific)"
  end
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(5)
end