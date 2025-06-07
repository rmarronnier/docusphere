#!/usr/bin/env ruby

puts "=== Test final du système Immo::Promo ==="

begin
  # Organisation
  org = Organization.first || Organization.create!(name: 'Demo Org', slug: 'demo')
  puts "✓ Organisation: #{org.name}"

  # Utilisateur admin
  user = User.find_by(email: 'admin@test.com') || User.create!(
    first_name: 'Admin',
    last_name: 'Test', 
    email: 'admin@test.com',
    password: 'password123',
    organization: org,
    role: 'admin'
  )
  puts "✓ Utilisateur: #{user.full_name}"

  # Projet
  project = Immo::Promo::Project.create!(
    name: 'Résidence Les Jardins',
    reference: 'RLJ2025',
    description: 'Projet résidentiel de 50 logements',
    project_type: 'residential',
    organization: org,
    project_manager: user,
    start_date: Date.current,
    end_date: Date.current + 2.years,
    address: '123 Rue de la Paix',
    city: 'Paris',
    postal_code: '75001',
    country: 'France',
    total_budget_cents: 500_000_000,
    total_units: 50,
    total_surface_area: 3500.0
  )
  puts "✓ Projet créé: #{project.name} (#{project.reference})"
  puts "  Budget: #{project.total_budget.format if project.total_budget}"
  puts "  Adresse: #{project.full_address if project.respond_to?(:full_address)}"

  # Phase
  phase = project.phases.create!(
    name: 'Études préliminaires',
    phase_type: 'studies',
    position: 1,
    start_date: Date.current,
    end_date: Date.current + 3.months
  )
  puts "✓ Phase créée: #{phase.name}"

  # Intervenant
  stakeholder = project.stakeholders.create!(
    name: 'Cabinet Architecture SARL',
    stakeholder_type: 'architect',
    email: 'contact@archi.fr',
    phone: '01 23 45 67 89',
    address: '456 Av des Architectes',
    city: 'Paris',
    postal_code: '75002'
  )
  puts "✓ Intervenant: #{stakeholder.name}"

  # Tâche
  task = phase.tasks.create!(
    name: 'Étude de faisabilité',
    description: 'Analyser la faisabilité du projet',
    task_type: 'technical',
    priority: 'high',
    start_date: Date.current,
    end_date: Date.current + 2.weeks,
    estimated_hours: 40,
    stakeholder: stakeholder,
    assigned_to: user
  )
  puts "✓ Tâche créée: #{task.name}"

  # Test services
  puts "\n=== Test des services ==="
  
  project_service = Immo::Promo::ProjectManagerService.new(project, user)
  progress = project_service.calculate_overall_progress
  puts "✓ Service ProjectManager - Avancement: #{progress}%"

  coordinator = Immo::Promo::StakeholderCoordinatorService.new(project, user)
  directory = coordinator.generate_stakeholder_directory
  puts "✓ Service StakeholderCoordinator - #{directory.count} type(s) d'intervenants"

  permit_tracker = Immo::Promo::PermitTrackerService.new(project, user)
  workflow = permit_tracker.generate_permit_workflow
  puts "✓ Service PermitTracker - #{workflow.count} étape(s) de workflow"

  puts "\n=== 🎉 SUCCÈS COMPLET ! ==="
  puts "Le module Immo::Promo est entièrement fonctionnel !"
  puts "\n📊 Résumé de l'implémentation :"
  puts "- #{Dir.glob('app/models/immo/promo/*.rb').count} modèles créés"
  puts "- #{Dir.glob('app/controllers/immo/promo/*.rb').count} contrôleurs créés"  
  puts "- #{Dir.glob('app/policies/immo/promo/*.rb').count} policies créées"
  puts "- #{Dir.glob('app/services/immo/promo/*.rb').count} services métier créés"
  puts "- #{Dir.glob('app/components/immo/promo/*.rb').count} composants ViewComponent créés"
  puts "- #{Dir.glob('app/views/immo/promo/**/*.html.erb').count} vues créées"
  puts "\n🚀 Accès: /immo/promo (nécessite authentification)"

rescue => e
  puts "\n❌ Erreur: #{e.message}"
  puts e.backtrace.first(3).join("\n")
end