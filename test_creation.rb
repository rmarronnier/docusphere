#!/usr/bin/env ruby

# Test de création des données
puts "=== Test de création des modèles Immo::Promo ==="

# Création d'une organisation de test
org = Organization.first || Organization.create!(
  name: 'Test Organization', 
  slug: 'test-org'
)
puts "Organisation: #{org.name}"

# Création d'un utilisateur de test
user = User.find_by(email: 'test@test.com') || User.create!(
  first_name: 'John', 
  last_name: 'Doe', 
  email: 'test@test.com', 
  password: 'password123', 
  organization: org,
  role: 'admin',
  permissions: ['immo_promo:access', 'immo_promo:projects:create']
)
puts "Utilisateur: #{user.full_name} (#{user.email})"

# Création d'un projet immobilier
project = Immo::Promo::Project.create!(
  name: 'Résidence Les Jardins',
  reference: 'RLJ2024',
  description: 'Projet de promotion immobilière de 50 logements',
  project_type: 'residential',
  organization: org,
  project_manager: user,
  address: '123 Rue de la Paix',
  city: 'Paris',
  postal_code: '75001',
  country: 'France',
  start_date: Date.current,
  end_date: Date.current + 2.years,
  total_budget_cents: 500_000_000, # 5M EUR
  total_units: 50,
  total_surface_area: 3500.0
)
puts "Projet créé: #{project.name} (#{project.reference})"
puts "Budget: #{project.total_budget.format if project.total_budget}"

# Création des phases par défaut
phases_data = [
  { name: 'Études préliminaires', phase_type: 'studies', position: 1 },
  { name: 'Obtention des permis', phase_type: 'permits', position: 2 },
  { name: 'Travaux de construction', phase_type: 'construction', position: 3 },
  { name: 'Réception des travaux', phase_type: 'reception', position: 4 },
  { name: 'Livraison', phase_type: 'delivery', position: 5 }
]

phases_data.each do |phase_data|
  phase = project.phases.create!(phase_data)
  puts "  Phase créée: #{phase.name}"
end

# Création d'un intervenant
stakeholder = project.stakeholders.create!(
  name: 'Architectes Associés SARL',
  stakeholder_type: 'architect',
  email: 'contact@architectes-associes.fr',
  phone: '01 23 45 67 89',
  address: '456 Avenue des Architectes',
  city: 'Paris',
  postal_code: '75002',
  country: 'France'
)
puts "Intervenant créé: #{stakeholder.name}"

# Création d'une tâche
first_phase = project.phases.first
task = first_phase.tasks.create!(
  name: 'Étude de faisabilité',
  description: 'Analyser la faisabilité technique et financière du projet',
  task_type: 'technical',
  priority: 'high',
  start_date: Date.current,
  end_date: Date.current + 2.weeks,
  estimated_hours: 40,
  stakeholder: stakeholder,
  assigned_to: user
)
puts "Tâche créée: #{task.name}"

# Test des services
puts "\n=== Test des services ==="

# Test du service de gestion de projet
project_service = Immo::Promo::ProjectManagerService.new(project, user)
progress = project_service.calculate_overall_progress
puts "Avancement global: #{progress}%"

alerts = project_service.generate_schedule_alerts
puts "Alertes: #{alerts.count} alerte(s) générée(s)"

# Test du service de coordination
coordinator_service = Immo::Promo::StakeholderCoordinatorService.new(project, user)
directory = coordinator_service.generate_stakeholder_directory
puts "Annuaire: #{directory.keys.count} type(s) d'intervenant(s)"

puts "\n=== Tests terminés avec succès ! ==="
puts "Projet ID: #{project.id}"
puts "Accès: /immo/promo/projects/#{project.id}"