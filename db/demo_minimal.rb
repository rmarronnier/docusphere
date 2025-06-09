# Minimal demo data for quick setup
puts "Creating minimal demo data..."

# Create main organization
org = Organization.find_or_create_by!(name: "DocuSphere Demo") do |o|
  o.description = "Organisation de démonstration"
  o.org_type = "enterprise"
  o.settings = { theme: "professional", features: ["ged", "immo_promo"] }
end

# Create demo users
admin = User.find_or_create_by!(email: "admin@docusphere.fr") do |u|
  u.password = "password123"
  u.first_name = "Admin"
  u.last_name = "Demo"
  u.organization = org
  u.role = "admin"
  u.confirmed_at = Time.current
end

manager = User.find_or_create_by!(email: "manager@docusphere.fr") do |u|
  u.password = "password123"
  u.first_name = "Chef"
  u.last_name = "Projet"
  u.organization = org
  u.role = "manager"
  u.confirmed_at = Time.current
end

# Create minimal GED structure
space = Space.find_or_create_by!(
  name: "Espace Principal",
  organization: org
) do |s|
  s.description = "Espace de travail principal"
  s.space_type = "project"
end

folder = Folder.find_or_create_by!(
  name: "Documents Projets",
  space: space
) do |f|
  f.description = "Documents des projets immobiliers"
end

# Create ImmoPromo demo project
if defined?(Immo::Promo::Project)
  project = Immo::Promo::Project.find_or_create_by!(
    name: "Résidence Les Jardins",
    organization: org
  ) do |p|
    p.project_type = "residential"
    p.status = "in_progress"
    p.description = "Projet résidentiel de 48 logements"
    p.start_date = 3.months.ago
    p.end_date = 9.months.from_now
    p.address = "123 Avenue des Fleurs"
    p.city = "Paris"
    p.postal_code = "75001"
    p.total_budget_cents = 12_000_000_00
    p.total_units = 48
    p.project_manager = manager
  end

  # Create basic phases
  phases = [
    { name: "Études", phase_type: "studies", status: "completed", position: 1 },
    { name: "Permis", phase_type: "permits", status: "in_progress", position: 2 },
    { name: "Construction", phase_type: "construction", status: "pending", position: 3 },
    { name: "Livraison", phase_type: "delivery", status: "pending", position: 4 }
  ]

  phases.each do |phase_data|
    Immo::Promo::Phase.find_or_create_by!(
      project: project,
      name: phase_data[:name]
    ) do |phase|
      phase.phase_type = phase_data[:phase_type]
      phase.status = phase_data[:status]
      phase.position = phase_data[:position]
      phase.start_date = phase_data[:position].months.ago
      phase.end_date = (phase_data[:position] * 2).months.from_now
    end
  end

  # Create a few stakeholders
  stakeholders = [
    { name: "Architecture Plus", stakeholder_type: "architect", email: "contact@archiplus.fr" },
    { name: "BTP Excellence", stakeholder_type: "contractor", email: "info@btpexcellence.fr" },
    { name: "Contrôle Tech", stakeholder_type: "inspector", email: "controle@techcontrol.fr" }
  ]

  stakeholders.each do |stake_data|
    Immo::Promo::Stakeholder.find_or_create_by!(
      project: project,
      email: stake_data[:email]
    ) do |s|
      s.name = stake_data[:name]
      s.stakeholder_type = stake_data[:stakeholder_type]
      s.company_name = stake_data[:name]
      s.status = "active"
    end
  end

  puts "✅ ImmoPromo demo project created"
end

# Create a few sample documents if files exist
sample_files = Dir.glob(Rails.root.join("storage", "sample_documents", "*.{pdf,md}")).first(3)

sample_files.each_with_index do |file_path, index|
  next unless File.exist?(file_path)
  
  doc = Document.find_or_create_by!(
    title: "Document exemple #{index + 1}",
    uploaded_by: admin,
    space: space,
    folder: folder
  ) do |d|
    d.description = "Document de démonstration"
    d.document_category = ["technical", "financial", "permit"][index] || "project"
  end
  
  unless doc.file.attached?
    doc.file.attach(
      io: File.open(file_path),
      filename: File.basename(file_path),
      content_type: "application/pdf"
    )
  end
end

puts "✅ Demo data created successfully!"
puts ""
puts "Login credentials:"
puts "  Admin: admin@docusphere.fr / password123"
puts "  Manager: manager@docusphere.fr / password123"
puts ""
puts "Ready for demo! 🚀"