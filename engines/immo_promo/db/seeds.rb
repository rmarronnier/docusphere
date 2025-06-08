# Engine ImmoPromo Seeds
# Permet de créer des données de test avec différents profils utilisateur
# Usage: rails immo_promo:db:seed

puts "🏗️  Création des seeds ImmoPromo..."

# Mot de passe commun pour tous les utilisateurs de test
common_password = "test123"

# Organisation principale
organization = Organization.find_or_create_by(name: "Promotex Immobilier") do |org|
  org.slug = "promotex"
end

puts "✅ Organisation créée: #{organization.name}"

# =============================================================================
# PROFILS UTILISATEUR
# =============================================================================

users = {}

# 1. Directeur de projet (super_admin)
users[:director] = User.find_or_create_by(email: "directeur@promotex.fr") do |user|
  user.first_name = "Marie"
  user.last_name = "Dubois"
  user.role = "super_admin"
  user.password = common_password
  user.password_confirmation = common_password
  user.organization = organization
  user.permissions = {
    'immo_promo:access' => true,
    'immo_promo:manage' => true,
    'immo_promo:admin' => true
  }
end

# 2. Chef de projet (admin)
users[:project_manager] = User.find_or_create_by(email: "chef.projet@promotex.fr") do |user|
  user.first_name = "Pierre"
  user.last_name = "Martin"
  user.role = "admin"
  user.password = common_password
  user.password_confirmation = common_password
  user.organization = organization
  user.permissions = {
    'immo_promo:access' => true,
    'immo_promo:manage' => true
  }
end

# 3. Architecte (manager)
users[:architect] = User.find_or_create_by(email: "architecte@promotex.fr") do |user|
  user.first_name = "Sophie"
  user.last_name = "Leroy"
  user.role = "manager"
  user.password = common_password
  user.password_confirmation = common_password
  user.organization = organization
  user.permissions = {
    'immo_promo:access' => true
  }
end

# 4. Commercial (user)
users[:sales] = User.find_or_create_by(email: "commercial@promotex.fr") do |user|
  user.first_name = "Jean"
  user.last_name = "Dupont"
  user.role = "user"
  user.password = common_password
  user.password_confirmation = common_password
  user.organization = organization
  user.permissions = {
    'immo_promo:access' => true
  }
end

# 5. Contrôleur de gestion (manager)
users[:controller] = User.find_or_create_by(email: "controle@promotex.fr") do |user|
  user.first_name = "Anne"
  user.last_name = "Moreau"
  user.role = "manager"
  user.password = common_password
  user.password_confirmation = common_password
  user.organization = organization
  user.permissions = {
    'immo_promo:access' => true
  }
end

puts "✅ #{users.count} utilisateurs créés avec le mot de passe: #{common_password}"

# =============================================================================
# PROJETS IMMOBILIERS
# =============================================================================

projects = {}

# Projet 1: Résidence Les Jardins (en cours)
projects[:gardens] = Immo::Promo::Project.find_or_create_by(
  name: "Résidence Les Jardins",
  organization: organization
) do |project|
  project.reference_number = "RLJ-2024-001"
  project.project_type = "residential"
  project.description = "Programme de 45 logements avec espaces verts"
  project.start_date = 3.months.ago
  project.expected_completion_date = 18.months.from_now
  project.total_budget_cents = 8_500_000_00
  project.total_area = 3200
  project.total_units = 45
  project.city = "Lyon"
  project.address = "Lyon 3ème arrondissement"
  project.status = "construction"
end

# Projet 2: Tour Horizon (planification)
projects[:tower] = Immo::Promo::Project.find_or_create_by(
  name: "Tour Horizon",
  organization: organization
) do |project|
  project.reference_number = "TH-2024-002"
  project.project_type = "mixed"
  project.description = "Tour mixte bureaux/logements de 15 étages"
  project.start_date = 6.months.from_now
  project.expected_completion_date = 36.months.from_now
  project.total_budget_cents = 25_000_000_00
  project.total_area = 8500
  project.total_units = 120
  project.city = "Lyon"
  project.address = "Lyon Part-Dieu"
  project.status = "planning"
end

# Projet 3: Villa Lumière (terminé)
projects[:villa] = Immo::Promo::Project.find_or_create_by(
  name: "Villa Lumière",
  organization: organization
) do |project|
  project.reference_number = "VL-2023-003"
  project.project_type = "residential"
  project.description = "Villa de prestige avec vue panoramique"
  project.start_date = 12.months.ago
  project.expected_completion_date = 1.month.ago
  project.total_budget_cents = 2_800_000_00
  project.total_area = 450
  project.total_units = 1
  project.city = "Caluire-et-Cuire"
  project.address = "Caluire-et-Cuire"
  project.status = "completed"
end

puts "✅ #{projects.count} projets créés"

# =============================================================================
# PHASES DES PROJETS
# =============================================================================

# Phases pour Résidence Les Jardins
gardens_phases = [
  {
    name: "Planification préliminaires",
    phase_type: "studies",
    status: "completed",
    start_date: 3.months.ago,
    end_date: 2.months.ago,
    progress_percentage: 100
  },
  {
    name: "Obtention des permis",
    phase_type: "permits",
    status: "in_progress",
    start_date: 2.months.ago,
    end_date: 1.month.from_now,
    progress_percentage: 70
  },
  {
    name: "Travaux de construction",
    phase_type: "construction",
    status: "pending",
    start_date: 2.months.from_now,
    end_date: 16.months.from_now,
    progress_percentage: 0
  }
]

gardens_phases.each do |phase_data|
  Immo::Promo::Phase.find_or_create_by(
    name: phase_data[:name],
    project: projects[:gardens]
  ) do |phase|
    phase.assign_attributes(phase_data)
  end
end

# Phases pour Tour Horizon
tower_phases = [
  {
    name: "Étude de faisabilité",
    phase_type: "studies",
    status: "in_progress",
    start_date: Date.current,
    end_date: 4.months.from_now,
    progress_percentage: 25
  },
  {
    name: "Conception architectural",
    phase_type: "studies",
    status: "pending",
    start_date: 3.months.from_now,
    end_date: 8.months.from_now,
    progress_percentage: 0
  }
]

tower_phases.each do |phase_data|
  Immo::Promo::Phase.find_or_create_by(
    name: phase_data[:name],
    project: projects[:tower]
  ) do |phase|
    phase.assign_attributes(phase_data)
  end
end

puts "✅ Phases créées pour les projets"

# =============================================================================
# INTERVENANTS/STAKEHOLDERS
# =============================================================================

stakeholders_data = [
  # Pour Résidence Les Jardins
  {
    project: projects[:gardens],
    name: "Cabinet Martin Architecture",
    stakeholder_type: "architect",
    email: "contact@martin-archi.fr",
    phone: "04 72 00 00 01",
    company_name: "Cabinet Martin Architecture",
    contact_person: "Architecte Martin",
    is_active: true,
    is_primary: true
  },
  {
    project: projects[:gardens],
    name: "BTP Constructions Lyon",
    stakeholder_type: "contractor",
    email: "projet@btp-lyon.fr",
    phone: "04 72 00 00 02",
    company_name: "BTP Constructions Lyon",
    contact_person: "Chef de chantier Dubois",
    is_active: true,
    is_primary: false
  },
  # Pour Tour Horizon
  {
    project: projects[:tower],
    name: "Atelier Horizon Design",
    stakeholder_type: "architect",
    email: "contact@horizon-design.fr",
    phone: "04 72 00 00 03",
    company_name: "Atelier Horizon Design",
    contact_person: "Architecte Lefevre",
    is_active: true,
    is_primary: true
  },
  {
    project: projects[:tower],
    name: "Bureau d'études Technique Plus",
    stakeholder_type: "engineer",
    email: "technique@tecplus.fr",
    phone: "04 72 00 00 04",
    company_name: "Technique Plus",
    contact_person: "Ingénieur Roux",
    is_active: true,
    is_primary: false
  }
]

stakeholders_data.each do |stakeholder_data|
  Immo::Promo::Stakeholder.find_or_create_by(
    name: stakeholder_data[:name],
    project: stakeholder_data[:project]
  ) do |stakeholder|
    stakeholder.assign_attributes(stakeholder_data)
  end
end

puts "✅ Intervenants créés"

# =============================================================================
# PERMIS ET AUTORISATIONS
# =============================================================================

permits_data = [
  # Pour Résidence Les Jardins
  {
    project: projects[:gardens],
    name: "Permis de construire principal",
    permit_type: "construction",
    permit_number: "PC-069-001-2024",
    status: "approved",
    issuing_authority: "Mairie de Lyon 3ème",
    submitted_date: 2.months.ago,
    approval_date: 1.month.ago,
    expiry_date: 23.months.from_now,
    cost: 2500.00,
    expected_approval_date: 1.month.ago
  },
  {
    project: projects[:gardens],
    name: "Autorisation de voirie",
    permit_type: "modification",
    permit_number: "AV-069-002-2024",
    status: "submitted",
    issuing_authority: "Métropole de Lyon",
    submitted_date: 3.weeks.ago,
    expiry_date: 12.months.from_now,
    cost: 800.00,
    expected_approval_date: 1.week.from_now
  },
  # Pour Tour Horizon
  {
    project: projects[:tower],
    name: "Permis de construire tour",
    permit_type: "construction",
    permit_number: "PC-069-003-2024",
    status: "draft",
    issuing_authority: "Mairie de Lyon 3ème",
    cost: 8500.00,
    expected_approval_date: 8.months.from_now
  }
]

permits_data.each do |permit_data|
  Immo::Promo::Permit.find_or_create_by(
    permit_number: permit_data[:permit_number],
    project: permit_data[:project]
  ) do |permit|
    permit.assign_attributes(permit_data)
  end
end

puts "✅ Permis créés"

# =============================================================================
# TÂCHES
# =============================================================================

# Récupération des phases pour créer des tâches
gardens_planning_phase = projects[:gardens].phases.find_by(phase_type: "planning")
gardens_permits_phase = projects[:gardens].phases.find_by(phase_type: "permits")
tower_planning_phase = projects[:tower].phases.find_by(phase_type: "planning")

# Récupération des stakeholders
gardens_architect = projects[:gardens].stakeholders.find_by(stakeholder_type: "architect")
gardens_contractor = projects[:gardens].stakeholders.find_by(stakeholder_type: "contractor")
tower_architect = projects[:tower].stakeholders.find_by(stakeholder_type: "architect")

tasks_data = [
  # Tâches Résidence Les Jardins
  {
    name: "Étude géotechnique du terrain",
    description: "Analyse complète du sol pour validation des fondations",
    phase: gardens_planning_phase,
    stakeholder: gardens_architect,
    assigned_to: users[:architect],
    status: "completed",
    priority: "high",
    start_date: 3.months.ago,
    end_date: 2.months.ago,
    actual_end_date: 2.months.ago,
    estimated_hours: 40,
    actual_hours: 42
  },
  {
    name: "Dépôt du permis de construire",
    description: "Constitution et dépôt du dossier complet en mairie",
    phase: gardens_permits_phase,
    stakeholder: gardens_architect,
    assigned_to: users[:project_manager],
    status: "completed",
    priority: "critical",
    start_date: 2.months.ago,
    end_date: 6.weeks.ago,
    actual_end_date: 6.weeks.ago,
    estimated_hours: 20,
    actual_hours: 18
  },
  {
    name: "Obtention autorisation voirie",
    description: "Démarches pour l'autorisation d'occupation de voirie",
    phase: gardens_permits_phase,
    stakeholder: gardens_contractor,
    assigned_to: users[:project_manager],
    status: "in_progress",
    priority: "high",
    start_date: 3.weeks.ago,
    end_date: 1.week.from_now,
    estimated_hours: 15
  },
  # Tâches Tour Horizon
  {
    name: "Étude de marché immobilier",
    description: "Analyse du marché local pour dimensionnement du programme",
    phase: tower_planning_phase,
    stakeholder: tower_architect,
    assigned_to: users[:sales],
    status: "in_progress",
    priority: "medium",
    start_date: 2.weeks.ago,
    end_date: 2.weeks.from_now,
    estimated_hours: 60
  },
  {
    name: "Pré-étude architecturale",
    description: "Esquisse préliminaire et validation concept",
    phase: tower_planning_phase,
    stakeholder: tower_architect,
    assigned_to: users[:architect],
    status: "pending",
    priority: "high",
    start_date: 1.week.from_now,
    end_date: 6.weeks.from_now,
    estimated_hours: 120
  }
]

tasks_data.each do |task_data|
  next unless task_data[:phase] && task_data[:stakeholder] # Skip si phase ou stakeholder manquant

  Immo::Promo::Task.find_or_create_by(
    name: task_data[:name],
    phase: task_data[:phase]
  ) do |task|
    task.assign_attributes(task_data)
  end
end

puts "✅ Tâches créées"

# =============================================================================
# BUDGETS
# =============================================================================

# Budget pour Résidence Les Jardins
gardens_budget = Immo::Promo::Budget.find_or_create_by(project: projects[:gardens]) do |budget|
  budget.name = "Budget principal Résidence Les Jardins"
  budget.budget_type = "initial"
  budget.version = 1
  budget.total_amount_cents = 8_500_000_00
  budget.spent_amount_cents = 2_100_000_00
  budget.is_current = true
end

# Lignes budgétaires pour Résidence Les Jardins
budget_lines_gardens = [
  {
    name: "Acquisition terrain",
    category: "land_acquisition",
    planned_amount_cents: 2_500_000_00,
    actual_amount_cents: 2_500_000_00
  },
  {
    name: "Planification et plans",
    category: "studies",
    planned_amount_cents: 250_000_00,
    actual_amount_cents: 280_000_00
  },
  {
    name: "Travaux de construction",
    category: "construction_work",
    planned_amount_cents: 4_800_000_00,
    actual_amount_cents: 0
  },
  {
    name: "Marketing et commercialisation",
    category: "marketing",
    planned_amount_cents: 450_000_00,
    actual_amount_cents: 50_000_00
  },
  {
    name: "Frais légaux et administratifs",
    category: "legal",
    planned_amount_cents: 300_000_00,
    actual_amount_cents: 180_000_00
  },
  {
    name: "Contingences",
    category: "contingency",
    planned_amount_cents: 200_000_00,
    actual_amount_cents: 0
  }
]

budget_lines_gardens.each do |line_data|
  Immo::Promo::BudgetLine.find_or_create_by(
    category: line_data[:category],
    budget: gardens_budget
  ) do |line|
    line.assign_attributes(line_data.except(:name))
  end
end

puts "✅ Budgets et lignes budgétaires créés"

# =============================================================================
# CONTRATS
# =============================================================================

contracts_data = [
  {
    project: projects[:gardens],
    stakeholder: gardens_architect,
    contract_type: "architecture",
    amount_cents: 180_000_00,
    status: "active",
    start_date: 3.months.ago,
    end_date: 12.months.from_now,
    description: "Contrat de maîtrise d'œuvre architecturale"
  },
  {
    project: projects[:gardens],
    stakeholder: gardens_contractor,
    contract_type: "construction",
    amount_cents: 4_200_000_00,
    status: "draft",
    start_date: 2.months.from_now,
    end_date: 14.months.from_now,
    description: "Contrat général de construction"
  },
  {
    project: projects[:tower],
    stakeholder: tower_architect,
    contract_type: "architecture",
    amount_cents: 420_000_00,
    status: "negotiation",
    start_date: 3.months.from_now,
    end_date: 24.months.from_now,
    description: "Contrat de conception architecturale"
  }
]

contracts_data.each do |contract_data|
  Immo::Promo::Contract.find_or_create_by(
    project: contract_data[:project],
    stakeholder: contract_data[:stakeholder],
    contract_type: contract_data[:contract_type]
  ) do |contract|
    contract.assign_attributes(contract_data)
  end
end

puts "✅ Contrats créés"

# =============================================================================
# JALONS (MILESTONES)
# =============================================================================

# Récupérer les phases pour attribuer les milestones
gardens_permits_phase = projects[:gardens].phases.find_by(phase_type: "permits")
gardens_construction_phase = projects[:gardens].phases.find_by(phase_type: "construction")
tower_studies_phase = projects[:tower].phases.find_by(phase_type: "studies")

milestones_data = [
  # Résidence Les Jardins
  {
    phase: gardens_permits_phase,
    name: "Obtention du permis de construire",
    milestone_type: "permit_approval",
    due_date: 1.month.ago,
    status: "completed",
    completion_date: 1.month.ago,
    description: "Permis obtenu dans les délais"
  },
  {
    phase: gardens_construction_phase,
    name: "Démarrage des travaux",
    milestone_type: "construction_start",
    due_date: 2.months.from_now,
    status: "pending",
    description: "Lancement officiel du chantier"
  },
  {
    phase: gardens_construction_phase,
    name: "Livraison première tranche",
    milestone_type: "delivery",
    due_date: 12.months.from_now,
    status: "pending",
    description: "Livraison des 25 premiers logements"
  },
  # Tour Horizon
  {
    phase: tower_studies_phase,
    name: "Validation concept architectural",
    milestone_type: "permit_submission",
    due_date: 4.months.from_now,
    status: "pending",
    description: "Approbation du design final"
  }
]

milestones_data.each do |milestone_data|
  next unless milestone_data[:phase] # Skip si phase manquante
  
  Immo::Promo::Milestone.find_or_create_by(
    name: milestone_data[:name],
    phase: milestone_data[:phase]
  ) do |milestone|
    milestone.assign_attributes(milestone_data)
  end
end

puts "✅ Jalons créés"

puts ""
puts "🎉 Seeds ImmoPromo créés avec succès !"
puts ""
puts "👥 UTILISATEURS CRÉÉS (mot de passe: #{common_password}):"
puts "   📧 directeur@promotex.fr (Directeur - super_admin)"
puts "   📧 chef.projet@promotex.fr (Chef de projet - admin)"  
puts "   📧 architecte@promotex.fr (Architecte - manager)"
puts "   📧 commercial@promotex.fr (Commercial - user)"
puts "   📧 controle@promotex.fr (Contrôleur - manager)"
puts ""
puts "🏗️  PROJETS CRÉÉS:"
puts "   • Résidence Les Jardins (en cours - 3 phases, 3 tâches)"
puts "   • Tour Horizon (planification - 2 phases, 2 tâches)"  
puts "   • Villa Lumière (terminé)"
puts ""
puts "📋 DONNÉES CRÉÉES:"
puts "   • #{Immo::Promo::Stakeholder.count} intervenants"
puts "   • #{Immo::Promo::Permit.count} permis/autorisations"
puts "   • #{Immo::Promo::Task.count} tâches"
puts "   • #{Immo::Promo::Contract.count} contrats"
puts "   • #{Immo::Promo::Milestone.count} jalons"
puts "   • #{Immo::Promo::BudgetLine.count} lignes budgétaires"
puts ""
puts "🚀 Vous pouvez maintenant tester différents workflows utilisateur !"