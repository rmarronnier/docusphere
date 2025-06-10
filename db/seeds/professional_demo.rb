# Professional Demo Seeding - Phase 4
# Creates a realistic professional environment for DocuSphere demonstrations

require 'faker'

puts "🚀 Starting Professional Demo Seeding (Phase 4)..."

# Set locale for French names and data
Faker::Config.locale = 'fr'

# Clear existing data in development (with care for foreign key constraints)
if Rails.env.development?
  puts "🧹 Cleaning up existing data for fresh professional demo..."
  
  # Check if we already have a professional demo
  existing_org = Organization.find_by(name: "Groupe Immobilier Meridia")
  if existing_org
    puts "ℹ️  Professional demo already exists. Skipping to avoid duplicates."
    puts "📊 Current Status:"
    puts "  - Organizations: #{Organization.count}"
    puts "  - Users: #{User.count}"
    puts "  - Documents: #{Document.count}"
    puts "  - Projects: #{Immo::Promo::Project.count}"
    exit 0
  end
  
  puts "✅ Ready to create professional demo data..."
end

# Helper to create file content (reuse existing helper from main seeds)
def generate_file_content(file_type, title = nil, context = nil)
  case file_type
  when 'pdf'
    require 'prawn'
    Prawn::Document.new do |pdf|
      pdf.text title || "Document Professionnel", size: 20, style: :bold
      pdf.move_down 20
      pdf.text "Créé le : #{Date.current.strftime('%d/%m/%Y')}", size: 12
      pdf.text "Contexte : #{context}" if context
      pdf.move_down 20
      
      case context
      when 'permis'
        pdf.text "DEMANDE DE PERMIS DE CONSTRUIRE", size: 16, style: :bold
        pdf.move_down 10
        pdf.text "Référence : PC-#{Date.current.year}-#{rand(1000..9999)}"
        pdf.text "Adresse du terrain : #{Faker::Address.full_address}"
        pdf.text "Surface de plancher : #{rand(100..5000)} m²"
        pdf.text "Nombre de logements : #{rand(10..200)}"
      when 'budget'
        pdf.text "BUDGET PRÉVISIONNEL", size: 16, style: :bold
        pdf.move_down 10
        pdf.text "Total HT : #{rand(100_000..10_000_000).to_s.gsub(/\B(?=(\d{3})+(?!\d))/, ' ')} €"
        pdf.text "TVA (20%) : #{rand(20_000..2_000_000).to_s.gsub(/\B(?=(\d{3})+(?!\d))/, ' ')} €"
        pdf.text "Total TTC : #{rand(120_000..12_000_000).to_s.gsub(/\B(?=(\d{3})+(?!\d))/, ' ')} €"
      when 'contrat'
        pdf.text "CONTRAT D'ENTREPRISE", size: 16, style: :bold
        pdf.move_down 10
        pdf.text "Maître d'ouvrage : Groupe Immobilier Meridia"
        pdf.text "Entreprise : #{Faker::Company.name}"
        pdf.text "Montant : #{rand(10_000..1_000_000).to_s.gsub(/\B(?=(\d{3})+(?!\d))/, ' ')} € HT"
      else
        pdf.text Faker::Lorem.paragraphs(number: rand(3..6)).join("\n\n"), size: 10
      end
    end.render
  when 'docx', 'doc'
    content = "Document Word (#{file_type.upcase})\n"
    content += "="*50 + "\n\n"
    content += "Titre : #{title || 'Document Professionnel'}\n"
    content += "Date : #{Date.current.strftime('%d/%m/%Y')}\n"
    content += "Contexte : #{context}\n\n" if context
    
    case context
    when 'rapport'
      content += "RAPPORT MENSUEL D'ACTIVITÉ\n\n"
      content += "1. Synthèse exécutive\n"
      content += "2. Avancement des projets\n"
      content += "3. Indicateurs de performance\n"
      content += "4. Prochaines étapes\n\n"
    when 'note'
      content += "NOTE DE SERVICE\n\n"
      content += "À : Équipe projet\n"
      content += "De : Direction\n"
      content += "Objet : #{title}\n\n"
    end
    
    content += Faker::Lorem.paragraphs(number: rand(5..15)).join("\n\n")
    content
  when 'xlsx', 'xls'
    content = "Fichier Excel (#{file_type.upcase})\n"
    content += "Titre : #{title || 'Tableau de données'}\n"
    content += "Date : #{Date.current.strftime('%d/%m/%Y')}\n\n"
    
    if context == 'budget'
      content += "BUDGET DÉTAILLÉ\n"
      content += "Poste,Prévu,Réalisé,Écart\n"
      content += "Terrassement,50000,48500,-1500\n"
      content += "Gros œuvre,450000,465000,15000\n"
      content += "Second œuvre,320000,305000,-15000\n"
      content += "Finitions,180000,185000,5000\n"
    else
      headers = ["ID", "Nom", "Date", "Montant", "Statut"]
      content += headers.join(",") + "\n"
      rand(10..20).times do |i|
        row = [i+1, Faker::Company.name, Faker::Date.backward(days: 365).strftime('%d/%m/%Y'), 
               rand(1000..50000), ["En cours", "Terminé", "En attente"].sample]
        content += row.join(",") + "\n"
      end
    end
    content
  else
    "Contenu du fichier #{file_type} - #{title || 'Document'}\n\n#{Faker::Lorem.paragraphs(number: 3).join("\n\n")}"
  end
end

# 🏢 Create main organization
puts "🏢 Creating Groupe Immobilier Meridia..."
main_org = Organization.create!(
  name: "Groupe Immobilier Meridia",
  slug: "meridia-groupe"
)

# 👥 Create realistic professional users
puts "👥 Creating 22 professional users with realistic profiles..."

# Direction (3)
marie_dubois = User.create!(
  email: "marie.dubois@meridia.fr",
  password: "password123",
  password_confirmation: "password123",
  first_name: "Marie",
  last_name: "Dubois",
  organization: main_org,
  role: "admin"
)

pierre_moreau = User.create!(
  email: "pierre.moreau@meridia.fr", 
  password: "password123",
  password_confirmation: "password123",
  first_name: "Pierre",
  last_name: "Moreau",
  organization: main_org,
  role: "admin"
)

sophie_martin = User.create!(
  email: "sophie.martin@meridia.fr",
  password: "password123", 
  password_confirmation: "password123",
  first_name: "Sophie",
  last_name: "Martin",
  organization: main_org,
  role: "manager"
)

# Chefs de Projet (5)
julien_leroy = User.create!(
  email: "julien.leroy@meridia.fr",
  password: "password123",
  password_confirmation: "password123", 
  first_name: "Julien",
  last_name: "Leroy",
  organization: main_org,
  role: "manager"
)

amelie_bernard = User.create!(
  email: "amelie.bernard@meridia.fr",
  password: "password123",
  password_confirmation: "password123",
  first_name: "Amélie", 
  last_name: "Bernard",
  organization: main_org,
  role: "manager"
)

thomas_petit = User.create!(
  email: "thomas.petit@meridia.fr",
  password: "password123",
  password_confirmation: "password123",
  first_name: "Thomas",
  last_name: "Petit", 
  organization: main_org,
  role: "user"
)

celine_rousseau = User.create!(
  email: "celine.rousseau@meridia.fr",
  password: "password123",
  password_confirmation: "password123",
  first_name: "Céline",
  last_name: "Rousseau",
  organization: main_org,
  role: "manager"
)

marc_fontaine = User.create!(
  email: "marc.fontaine@meridia.fr",
  password: "password123", 
  password_confirmation: "password123",
  first_name: "Marc",
  last_name: "Fontaine",
  organization: main_org,
  role: "manager"
)

# Technique (3)
francois_moreau = User.create!(
  email: "francois.moreau@meridia.fr",
  password: "password123",
  password_confirmation: "password123",
  first_name: "François",
  last_name: "Moreau",
  organization: main_org,
  role: "manager"
)

julie_garnier = User.create!(
  email: "julie.garnier@meridia.fr",
  password: "password123",
  password_confirmation: "password123", 
  first_name: "Julie",
  last_name: "Garnier",
  organization: main_org,
  role: "user"
)

david_lambert = User.create!(
  email: "david.lambert@meridia.fr",
  password: "password123",
  password_confirmation: "password123",
  first_name: "David",
  last_name: "Lambert",
  organization: main_org,
  role: "user"
)

# Finance/Contrôle (2)
nathalie_giraud = User.create!(
  email: "nathalie.giraud@meridia.fr",
  password: "password123",
  password_confirmation: "password123",
  first_name: "Nathalie",
  last_name: "Giraud",
  organization: main_org,
  role: "user"
)

vincent_roux = User.create!(
  email: "vincent.roux@meridia.fr",
  password: "password123",
  password_confirmation: "password123", 
  first_name: "Vincent",
  last_name: "Roux",
  organization: main_org,
  role: "user"
)

# Juridique (2)
isabelle_blanc = User.create!(
  email: "isabelle.blanc@meridia.fr",
  password: "password123",
  password_confirmation: "password123",
  first_name: "Isabelle",
  last_name: "Blanc",
  organization: main_org,
  role: "user"
)

alexandre_martin = User.create!(
  email: "alexandre.martin@meridia.fr",
  password: "password123",
  password_confirmation: "password123",
  first_name: "Alexandre", 
  last_name: "Martin",
  organization: main_org,
  role: "user"
)

# Commercial (3)
sylvie_dupont = User.create!(
  email: "sylvie.dupont@meridia.fr",
  password: "password123",
  password_confirmation: "password123",
  first_name: "Sylvie",
  last_name: "Dupont",
  organization: main_org,
  role: "manager"
)

nicolas_lefevre = User.create!(
  email: "nicolas.lefevre@meridia.fr",
  password: "password123",
  password_confirmation: "password123",
  first_name: "Nicolas",
  last_name: "Lefèvre",
  organization: main_org,
  role: "user"
)

camille_robert = User.create!(
  email: "camille.robert@meridia.fr", 
  password: "password123",
  password_confirmation: "password123",
  first_name: "Camille",
  last_name: "Robert",
  organization: main_org,
  role: "user"
)

# Create admin user for system access
admin = User.create!(
  email: "admin@meridia.fr",
  password: "password123",
  password_confirmation: "password123",
  first_name: "Admin",
  last_name: "Système",
  organization: main_org,
  role: "admin"
)

# Store all users for easy access
all_users = [marie_dubois, pierre_moreau, sophie_martin, julien_leroy, amelie_bernard, 
             thomas_petit, celine_rousseau, marc_fontaine, francois_moreau, julie_garnier,
             david_lambert, nathalie_giraud, vincent_roux, isabelle_blanc, alexandre_martin,
             sylvie_dupont, nicolas_lefevre, camille_robert, admin]

# 🎭 Create user profiles with realistic business contexts
puts "🎭 Creating user profiles with business specializations..."

# Direction profiles
marie_profile = UserProfile.create!(
  user: marie_dubois,
  profile_type: 'direction',
  active: true,
  preferences: {
    theme: 'corporate',
    language: 'fr',
    timezone: 'Europe/Paris',
    specialization: 'vision_strategique'
  }
)

pierre_profile = UserProfile.create!(
  user: pierre_moreau,
  profile_type: 'direction',
  active: true,
  preferences: {
    theme: 'corporate',
    language: 'fr', 
    timezone: 'Europe/Paris',
    specialization: 'operationnel'
  }
)

sophie_profile = UserProfile.create!(
  user: sophie_martin,
  profile_type: 'direction',
  active: true,
  preferences: {
    theme: 'modern',
    language: 'fr',
    timezone: 'Europe/Paris',
    specialization: 'residentiel'
  }
)

# Chef projet profiles  
julien_profile = UserProfile.create!(
  user: julien_leroy,
  profile_type: 'chef_projet',
  active: true,
  preferences: {
    theme: 'professional',
    language: 'fr',
    timezone: 'Europe/Paris',
    specialization: 'projets_complexes'
  }
)

amelie_profile = UserProfile.create!(
  user: amelie_bernard,
  profile_type: 'chef_projet', 
  active: true,
  preferences: {
    theme: 'modern',
    language: 'fr',
    timezone: 'Europe/Paris',
    specialization: 'projets_moyens'
  }
)

thomas_profile = UserProfile.create!(
  user: thomas_petit,
  profile_type: 'chef_projet',
  active: true,
  preferences: {
    theme: 'simple',
    language: 'fr',
    timezone: 'Europe/Paris',
    specialization: 'junior'
  }
)

celine_profile = UserProfile.create!(
  user: celine_rousseau,
  profile_type: 'chef_projet',
  active: true,
  preferences: {
    theme: 'professional',
    language: 'fr',
    timezone: 'Europe/Paris', 
    specialization: 'tertiaire'
  }
)

marc_profile = UserProfile.create!(
  user: marc_fontaine,
  profile_type: 'chef_projet',
  active: true,
  preferences: {
    theme: 'modern',
    language: 'fr',
    timezone: 'Europe/Paris',
    specialization: 'mixte_innovant'
  }
)

# Technique profiles
francois_profile = UserProfile.create!(
  user: francois_moreau,
  profile_type: 'architecte',
  active: true,
  preferences: {
    theme: 'technical',
    language: 'fr',
    timezone: 'Europe/Paris',
    specialization: 'architecture_chef'
  }
)

julie_profile = UserProfile.create!(
  user: julie_garnier,
  profile_type: 'architecte', 
  active: true,
  preferences: {
    theme: 'creative',
    language: 'fr',
    timezone: 'Europe/Paris',
    specialization: 'architecture_projet'
  }
)

david_profile = UserProfile.create!(
  user: david_lambert,
  profile_type: 'expert_technique',
  active: true,
  preferences: {
    theme: 'technical',
    language: 'fr',
    timezone: 'Europe/Paris',
    specialization: 'bet_structure'
  }
)

# Finance profiles
nathalie_profile = UserProfile.create!(
  user: nathalie_giraud,
  profile_type: 'controleur',
  active: true,
  preferences: {
    theme: 'corporate',
    language: 'fr',
    timezone: 'Europe/Paris',
    specialization: 'analyse_budgets'
  }
)

vincent_profile = UserProfile.create!(
  user: vincent_roux,
  profile_type: 'controleur',
  active: true,
  preferences: {
    theme: 'analytical',
    language: 'fr',
    timezone: 'Europe/Paris',
    specialization: 'reporting'
  }
)

# Juridique profiles
isabelle_profile = UserProfile.create!(
  user: isabelle_blanc,
  profile_type: 'juriste',
  active: true,
  preferences: {
    theme: 'corporate',
    language: 'fr',
    timezone: 'Europe/Paris',
    specialization: 'contrats_complexes'
  }
)

alexandre_profile = UserProfile.create!(
  user: alexandre_martin,
  profile_type: 'juriste',
  active: true,
  preferences: {
    theme: 'professional',
    language: 'fr',
    timezone: 'Europe/Paris',
    specialization: 'administratif'
  }
)

# Commercial profiles
sylvie_profile = UserProfile.create!(
  user: sylvie_dupont,
  profile_type: 'commercial',
  active: true,
  preferences: {
    theme: 'dynamic',
    language: 'fr',
    timezone: 'Europe/Paris',
    specialization: 'strategie_commerciale'
  }
)

nicolas_profile = UserProfile.create!(
  user: nicolas_lefevre,
  profile_type: 'commercial',
  active: true,
  preferences: {
    theme: 'sales',
    language: 'fr',
    timezone: 'Europe/Paris',
    specialization: 'gros_clients'
  }
)

camille_profile = UserProfile.create!(
  user: camille_robert,
  profile_type: 'commercial',
  active: true,
  preferences: {
    theme: 'friendly',
    language: 'fr',
    timezone: 'Europe/Paris',
    specialization: 'terrain'
  }
)

admin_profile = UserProfile.create!(
  user: admin,
  profile_type: 'assistant_rh',
  active: true
)

# Store profiles for easy access
all_profiles = [marie_profile, pierre_profile, sophie_profile, julien_profile, amelie_profile,
                thomas_profile, celine_profile, marc_profile, francois_profile, julie_profile,
                david_profile, nathalie_profile, vincent_profile, isabelle_profile, alexandre_profile,
                sylvie_profile, nicolas_profile, camille_profile, admin_profile]

puts "✅ Created #{all_users.count} professional users with specialized profiles"
puts "📧 Login examples:"
puts "   - marie.dubois@meridia.fr (PDG)"
puts "   - julien.leroy@meridia.fr (Chef Projet Senior)"
puts "   - francois.moreau@meridia.fr (Architecte Chef)"
puts "   - nathalie.giraud@meridia.fr (Contrôleur)"
puts "   - Password: password123"

# 👫 Create realistic user groups
puts "👫 Creating professional user groups..."

direction_group = UserGroup.create!(
  name: "Direction Générale",
  description: "Direction du groupe avec vision stratégique",
  organization: main_org,
  group_type: "department",
  is_active: true
)

chef_projet_group = UserGroup.create!(
  name: "Chefs de Projet",
  description: "Équipe de management de projets immobiliers",
  organization: main_org,
  group_type: "department", 
  is_active: true
)

technique_group = UserGroup.create!(
  name: "Équipe Technique",
  description: "Architectes et bureaux d'études techniques",
  organization: main_org,
  group_type: "department",
  is_active: true
)

finance_group = UserGroup.create!(
  name: "Contrôle de Gestion",
  description: "Finance et contrôle budgétaire",
  organization: main_org,
  group_type: "department",
  is_active: true
)

juridique_group = UserGroup.create!(
  name: "Service Juridique", 
  description: "Affaires juridiques et conformité",
  organization: main_org,
  group_type: "department",
  is_active: true
)

commercial_group = UserGroup.create!(
  name: "Équipe Commerciale",
  description: "Ventes et relation client",
  organization: main_org,
  group_type: "department",
  is_active: true
)

# Add memberships
UserGroupMembership.create!([
  { user: marie_dubois, user_group: direction_group, role: "admin" },
  { user: pierre_moreau, user_group: direction_group, role: "admin" },
  { user: sophie_martin, user_group: direction_group, role: "member" },
  
  { user: julien_leroy, user_group: chef_projet_group, role: "admin" },
  { user: amelie_bernard, user_group: chef_projet_group, role: "member" },
  { user: thomas_petit, user_group: chef_projet_group, role: "member" },
  { user: celine_rousseau, user_group: chef_projet_group, role: "member" },
  { user: marc_fontaine, user_group: chef_projet_group, role: "member" },
  
  { user: francois_moreau, user_group: technique_group, role: "admin" },
  { user: julie_garnier, user_group: technique_group, role: "member" },
  { user: david_lambert, user_group: technique_group, role: "member" },
  
  { user: nathalie_giraud, user_group: finance_group, role: "admin" },
  { user: vincent_roux, user_group: finance_group, role: "member" },
  
  { user: isabelle_blanc, user_group: juridique_group, role: "admin" },
  { user: alexandre_martin, user_group: juridique_group, role: "member" },
  
  { user: sylvie_dupont, user_group: commercial_group, role: "admin" },
  { user: nicolas_lefevre, user_group: commercial_group, role: "member" },
  { user: camille_robert, user_group: commercial_group, role: "member" }
])

# 📁 Create professional spaces structure
puts "📁 Creating professional space structure..."

# Direction space
direction_space = Space.create!(
  name: "Direction Générale",
  description: "Documents stratégiques et de direction",
  organization: main_org
)

# Grant access to direction group
direction_space.authorize_group(direction_group, 'admin', granted_by: admin)

# Project spaces for major projects
jardins_space = Space.create!(
  name: "Projet Jardins de Belleville", 
  description: "75 logements - Paris 20e - Livraison 2025",
  organization: main_org
)

horizon_space = Space.create!(
  name: "Résidence Horizon",
  description: "120 logements - Lyon Part-Dieu - Livraison 2026", 
  organization: main_org
)

alpha_space = Space.create!(
  name: "Business Center Alpha",
  description: "15000m² bureaux - La Défense - Livraison 2024",
  organization: main_org
)

# Service spaces
juridique_space = Space.create!(
  name: "Service Juridique",
  description: "Contrats, permis et affaires juridiques",
  organization: main_org
)

technique_space = Space.create!(
  name: "Documentation Technique",
  description: "Plans, études techniques et normes",
  organization: main_org
)

commercial_space = Space.create!(
  name: "Commercial & Marketing",
  description: "Documentation commerciale et marketing",
  organization: main_org
)

finance_space = Space.create!(
  name: "Contrôle de Gestion",
  description: "Budgets, reporting et analyses financières",
  organization: main_org
)

# Grant appropriate access to project spaces
[jardins_space, horizon_space, alpha_space].each do |project_space|
  project_space.authorize_group(direction_group, 'admin', granted_by: admin)
  project_space.authorize_group(chef_projet_group, 'write', granted_by: admin)
  project_space.authorize_group(technique_group, 'write', granted_by: admin)
  project_space.authorize_group(finance_group, 'read', granted_by: admin)
  project_space.authorize_group(juridique_group, 'read', granted_by: admin)
  project_space.authorize_group(commercial_group, 'read', granted_by: admin)
end

# Grant service-specific access
juridique_space.authorize_group(juridique_group, 'admin', granted_by: admin)
juridique_space.authorize_group(direction_group, 'read', granted_by: admin)

technique_space.authorize_group(technique_group, 'admin', granted_by: admin)
technique_space.authorize_group(chef_projet_group, 'write', granted_by: admin)

commercial_space.authorize_group(commercial_group, 'admin', granted_by: admin)
commercial_space.authorize_group(direction_group, 'read', granted_by: admin)

finance_space.authorize_group(finance_group, 'admin', granted_by: admin)
finance_space.authorize_group(direction_group, 'read', granted_by: admin)

# 🏷️ Create professional tags
puts "🏷️ Creating professional tag system..."

# Project tags
projet_tags = ["jardins-belleville", "residence-horizon", "business-alpha"].map do |tag_name|
  Tag.create!(name: tag_name, organization: main_org)
end

# Document type tags
type_tags = ["permis-construire", "budget-previsionnel", "contrat-entreprise", 
             "plan-architecture", "rapport-mensuel", "facture", "devis",
             "note-service", "proces-verbal", "correspondance"].map do |tag_name|
  Tag.create!(name: tag_name, organization: main_org)
end

# Status tags
status_tags = ["urgent", "en-cours", "valide", "archive", "brouillon", 
               "attente-signature", "confidentiel"].map do |tag_name|
  Tag.create!(name: tag_name, organization: main_org)
end

# Phase tags
phase_tags = ["etudes", "permis", "construction", "reception", "livraison",
              "pre-commercialisation", "commercialisation"].map do |tag_name|
  Tag.create!(name: tag_name, organization: main_org)
end

all_tags = projet_tags + type_tags + status_tags + phase_tags

# 📂 Create structured folders
puts "📂 Creating professional folder structure..."

# Direction folders
direction_folders = []
["Conseil Administration", "Comité Direction", "Stratégie", "Reporting Mensuel"].each do |folder_name|
  folder = Folder.create!(
    name: folder_name,
    description: "Dossier #{folder_name} - Direction",
    space: direction_space,
    slug: folder_name.parameterize
  )
  direction_folders << folder
end

# Project folders structure
[jardins_space, horizon_space, alpha_space].each do |project_space|
  project_folders = []
  
  ["00_Administratif", "01_Technique", "02_Commercial", "03_Financier", "04_Juridique"].each do |folder_name|
    main_folder = Folder.create!(
      name: folder_name,
      description: "Dossier #{folder_name.split('_').last} du projet",
      space: project_space,
      slug: folder_name.parameterize
    )
    project_folders << main_folder
    
    # Create subfolders based on folder type
    subfolders = case folder_name
                 when "00_Administratif"
                   ["Permis Construire", "Autorisations", "Correspondances"]
                 when "01_Technique" 
                   ["Plans Architecture", "Études Structure", "Bureaux Contrôle"]
                 when "02_Commercial"
                   ["Plaquettes", "Grilles Prix", "Réservations"]
                 when "03_Financier"
                   ["Budgets", "Factures", "Devis", "Avenants"]
                 when "04_Juridique"
                   ["Contrats", "VEFA", "Assurances"]
                 else
                   []
                 end
    
    subfolders.each do |subfolder_name|
      Folder.create!(
        name: subfolder_name,
        description: "Sous-dossier #{subfolder_name}",
        space: project_space,
        slug: "#{main_folder.slug}-#{subfolder_name.parameterize}",
        parent: main_folder
      )
    end
  end
end

# 🏗️ Create realistic professional projects using Immo::Promo module
puts "🏗️ Creating professional real estate projects..."

# Major residential projects  
jardins_project = Immo::Promo::Project.create!(
  name: "Les Jardins de Belleville",
  description: "Développement résidentiel premium de 75 logements dans le 20e arrondissement de Paris. Programme mixte avec commerces en rez-de-chaussée et espaces verts.",
  organization: main_org,
  project_type: "residential",
  status: "construction",
  address: "125 rue de Belleville",
  city: "Paris",
  postal_code: "75020", 
  total_area: 8500,
  total_units: 75,
  start_date: 8.months.ago,
  expected_completion_date: 16.months.from_now,
  project_manager: julien_leroy,
  land_area: 2800,
  building_permit_number: "PC-2024-1025",
  total_budget_cents: 2_800_000_00, # 28M euros
  current_budget_cents: 1_200_000_00, # 12M euros spent
  reference_number: "PROJ-JARDINS-#{Time.current.to_i}" # Explicit unique reference
)

# Add small delay to avoid timestamp collisions
sleep(0.1)

horizon_project = Immo::Promo::Project.create!(
  name: "Résidence Horizon",
  description: "Complexe résidentiel moderne de 120 logements à Lyon Part-Dieu. Architecture contemporaine avec services haut de gamme.",
  organization: main_org,
  project_type: "residential", 
  status: "pre_construction",
  address: "45 avenue Tony Garnier",
  city: "Lyon",
  postal_code: "69007",
  total_area: 12000,
  total_units: 120,
  start_date: 2.months.from_now,
  expected_completion_date: 26.months.from_now,
  project_manager: amelie_bernard,
  land_area: 3500,
  building_permit_number: "PC-2024-2156",
  total_budget_cents: 4_200_000_00, # 42M euros
  current_budget_cents: 500_000_00, # 5M euros spent (études)
  reference_number: "PROJ-HORIZON-#{Time.current.to_i}" # Explicit unique reference
)

# Add small delay to avoid timestamp collisions
sleep(0.1)

# Business center project
alpha_project = Immo::Promo::Project.create!(
  name: "Business Center Alpha",
  description: "Centre d'affaires premium de 15000m² à La Défense. Bureaux flexibles avec services intégrés et parking de 200 places.",
  organization: main_org,
  project_type: "commercial",
  status: "finishing",
  address: "8 place de la Défense",
  city: "Courbevoie", 
  postal_code: "92400",
  total_area: 15000,
  total_units: 50, # 50 bureaux/espaces
  start_date: 18.months.ago,
  expected_completion_date: 3.months.from_now,
  project_manager: celine_rousseau,
  land_area: 4200,
  building_permit_number: "PC-2023-5847",
  total_budget_cents: 6_800_000_00, # 68M euros
  current_budget_cents: 6_000_000_00, # 60M euros spent
  reference_number: "PROJ-ALPHA-#{Time.current.to_i}" # Explicit unique reference
)

all_projects = [jardins_project, horizon_project, alpha_project]

# 📄 Create professional business documents
puts "📄 Creating realistic business documents..."

document_templates = {
  permis: {
    title_templates: [
      "Permis de Construire PC-{year}-{number}",
      "Déclaration Préalable DP-{year}-{number}",
      "Autorisation Travaux AT-{year}-{number}"
    ],
    context: 'permis'
  },
  budget: {
    title_templates: [
      "Budget Prévisionnel {project}",
      "Analyse Coûts {project} - {quarter}",
      "Suivi Budgétaire {project}"
    ],
    context: 'budget'
  },
  contrat: {
    title_templates: [
      "Contrat Entreprise {company}",
      "Avenant {number} - {company}",
      "CCTP {trade} - {project}"
    ],
    context: 'contrat'
  },
  rapport: {
    title_templates: [
      "Rapport Mensuel {project} - {month}",
      "Compte Rendu Chantier {date}",
      "Bilan Avancement {project}"
    ],
    context: 'rapport'
  },
  note: {
    title_templates: [
      "Note de Service - {subject}",
      "Instruction Technique {number}",
      "Procès Verbal Réunion {date}"
    ],
    context: 'note'
  }
}

created_documents = []

# Create documents for each project space
[jardins_space, horizon_space, alpha_space].each_with_index do |project_space, project_index|
  project = all_projects[project_index]
  
  # Get project folders for document placement
  project_folders = Folder.where(space: project_space)
  
  # Create 25-30 documents per project
  rand(25..30).times do |doc_index|
    # Select document template
    doc_type, template_data = document_templates.to_a.sample
    title_template = template_data[:title_templates].sample
    
    # Generate realistic title
    title = title_template.gsub('{project}', project.name.split(' ').last)
                          .gsub('{year}', [2023, 2024, 2025].sample.to_s)
                          .gsub('{number}', rand(1000..9999).to_s)
                          .gsub('{quarter}', ["Q1", "Q2", "Q3", "Q4"].sample)
                          .gsub('{month}', Date::MONTHNAMES[rand(1..12)])
                          .gsub('{date}', rand(30.days).seconds.ago.strftime('%d-%m-%Y'))
                          .gsub('{subject}', ["Sécurité", "Planning", "Qualité", "Budget"].sample)
                          .gsub('{company}', ["BTP Services", "Construct Pro", "Build Expert"].sample)
                          .gsub('{trade}', ["Gros Œuvre", "Second Œuvre", "Finitions"].sample)
    
    # Select appropriate folder based on document type
    target_folder = case doc_type
                   when :permis then project_folders.find { |f| f.name.include?("00_Administratif") }&.children&.find { |f| f.name.include?("Permis") }
                   when :budget then project_folders.find { |f| f.name.include?("03_Financier") }&.children&.find { |f| f.name.include?("Budgets") }
                   when :contrat then project_folders.find { |f| f.name.include?("04_Juridique") }&.children&.find { |f| f.name.include?("Contrats") }
                   when :rapport then project_folders.find { |f| f.name.include?("00_Administratif") }&.children&.find { |f| f.name.include?("Correspondances") }
                   when :note then project_folders.find { |f| f.name.include?("01_Technique") }&.children&.first
                   end || project_folders.sample
    
    # Select appropriate uploader
    uploader = case doc_type
              when :permis then [francois_moreau, julie_garnier, alexandre_martin].sample
              when :budget then [nathalie_giraud, vincent_roux].sample
              when :contrat then [isabelle_blanc, alexandre_martin].sample 
              when :rapport then project.project_manager
              when :note then [marie_dubois, pierre_moreau, project.project_manager].sample
              else all_users.sample
              end
    
    # Determine file type based on document type
    file_type = case doc_type
               when :permis then 'pdf'
               when :budget then ['xlsx', 'pdf'].sample
               when :contrat then 'pdf'
               when :rapport then ['docx', 'pdf'].sample
               when :note then 'docx'
               else ['pdf', 'docx', 'xlsx'].sample
               end
    
    # Generate file content
    file_content = generate_file_content(file_type, title, template_data[:context])
    
    # Create document
    document = Document.new(
      title: title,
      description: "Document professionnel - #{project.name}",
      uploaded_by: uploader,
      space: project_space,
      folder: target_folder,
      status: ["published", "published", "draft", "locked"].sample
    )
    
    # Attach file
    document.file.attach(
      io: StringIO.new(file_content),
      filename: "#{title.parameterize}.#{file_type}",
      content_type: case file_type
                   when 'pdf' then 'application/pdf'
                   when 'docx' then 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
                   when 'xlsx' then 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
                   else 'text/plain'
                   end
    )
    
    if document.save
      created_documents << document
      
      # Add relevant tags
      relevant_tags = case doc_type
                     when :permis then all_tags.select { |t| t.name.in?(['permis-construire', 'urgent', project.name.parameterize.split('-').first]) }
                     when :budget then all_tags.select { |t| t.name.in?(['budget-previsionnel', 'en-cours', project.name.parameterize.split('-').first]) }
                     when :contrat then all_tags.select { |t| t.name.in?(['contrat-entreprise', 'valide', project.name.parameterize.split('-').first]) }
                     when :rapport then all_tags.select { |t| t.name.in?(['rapport-mensuel', 'en-cours', project.name.parameterize.split('-').first]) }
                     when :note then all_tags.select { |t| t.name.in?(['note-service', 'archive', project.name.parameterize.split('-').first]) }
                     end
      
      document.tags << relevant_tags.sample(rand(1..3))
      
      # Add professional metadata
      project_metadata = {
        "project_code" => project.name.parameterize.upcase,
        "project_phase" => case project.status
                          when "planning" then "etudes"
                          when "pre_construction" then "permis"
                          when "construction" then "construction"
                          when "finishing" then "reception"
                          else "livraison"
                          end,
        "document_category" => doc_type.to_s,
        "validation_required" => (doc_type.in?([:permis, :contrat]) ? "true" : "false"),
        "confidentiality" => case doc_type
                            when :contrat then "confidentiel"
                            when :budget then "interne"
                            else "public"
                            end
      }
      
      project_metadata.each do |key, value|
        Metadatum.create!(
          metadatable: document,
          key: key,
          value: value
        )
      end
      
      # Share important documents with relevant teams
      if doc_type.in?([:permis, :budget, :contrat])
        relevant_users = case doc_type
                        when :permis then [francois_moreau, alexandre_martin, project.project_manager]
                        when :budget then [nathalie_giraud, vincent_roux, marie_dubois]
                        when :contrat then [isabelle_blanc, project.project_manager, pierre_moreau]
                        end
        
        relevant_users.compact.uniq.each do |user|
          next if user == uploader
          Share.create!(
            shareable: document,
            shared_with: user,
            shared_by: uploader,
            access_level: "read",
            expires_at: nil
          )
        end
      end
    end
  end
end

# 🎭 Create specialized dashboard widgets for each user profile
puts "🎭 Creating personalized dashboard widgets..."

all_profiles.each do |profile|
  user = profile.user
  
  # Create 4-6 widgets per user based on their profile type
  widget_configs = case profile.profile_type
                  when 'direction'
                    [
                      { type: 'recent_documents', position: 1, config: { limit: 8, filter: 'important' } },
                      { type: 'statistics', position: 2, config: { metrics: ['total_projects', 'budget_consumed', 'active_permits'] } },
                      { type: 'pending_tasks', position: 3, config: { limit: 10, priority: 'high' } },
                      { type: 'notifications', position: 4, config: { types: ['validation_required', 'budget_alert'] } }
                    ]
                  when 'chef_projet'
                    [
                      { type: 'project_progress', position: 1, config: { projects: 'assigned' } },
                      { type: 'pending_tasks', position: 2, config: { limit: 12, status: 'in_progress' } },
                      { type: 'recent_documents', position: 3, config: { limit: 6, filter: 'project' } },
                      { type: 'team_activity', position: 4, config: { scope: 'project_team' } },
                      { type: 'budget_overview', position: 5, config: { type: 'project_specific' } }
                    ]
                  when 'architecte'
                    [
                      { type: 'documents_to_review', position: 1, config: { types: ['plans', 'permits'] } },
                      { type: 'technical_alerts', position: 2, config: { categories: ['compliance', 'deadlines'] } },
                      { type: 'recent_documents', position: 3, config: { limit: 8, filter: 'technical' } },
                      { type: 'project_milestones', position: 4, config: { phases: ['design', 'permits'] } }
                    ]
                  when 'controleur'
                    [
                      { type: 'budget_alerts', position: 1, config: { threshold: 0.8 } },
                      { type: 'pending_invoices', position: 2, config: { limit: 10 } },
                      { type: 'financial_overview', position: 3, config: { period: 'monthly' } },
                      { type: 'reports_due', position: 4, config: { types: ['budget', 'compliance'] } }
                    ]
                  when 'juriste'
                    [
                      { type: 'contracts_expiring', position: 1, config: { days_ahead: 60 } },
                      { type: 'permits_status', position: 2, config: { status: ['pending', 'review'] } },
                      { type: 'legal_documents', position: 3, config: { limit: 8 } },
                      { type: 'compliance_alerts', position: 4, config: { categories: ['regulatory', 'contractual'] } }
                    ]
                  when 'commercial'
                    [
                      { type: 'sales_pipeline', position: 1, config: { period: 'current_quarter' } },
                      { type: 'client_activity', position: 2, config: { limit: 10 } },
                      { type: 'marketing_materials', position: 3, config: { status: 'published' } },
                      { type: 'reservations_pending', position: 4, config: { priority: 'urgent' } }
                    ]
                  else
                    [
                      { type: 'recent_documents', position: 1, config: { limit: 6 } },
                      { type: 'pending_tasks', position: 2, config: { limit: 8 } },
                      { type: 'notifications', position: 3, config: { limit: 5 } }
                    ]
                  end
  
  widget_configs.each do |widget_config|
    DashboardWidget.create!(
      user_profile: profile,
      widget_type: widget_config[:type],
      position: widget_config[:position],
      width: case widget_config[:type]
           when 'statistics', 'financial_overview' then 2
           when 'recent_documents', 'pending_tasks' then 2  
           else 1
           end,
      height: case widget_config[:type]
           when 'statistics', 'financial_overview' then 2
           when 'recent_documents', 'pending_tasks' then 1  
           else 1
           end,
      config: widget_config[:config],
      visible: true
    )
  end
end

puts "\n🚀 Professional Demo seeding completed!"
puts "📊 Summary:"
puts "  - Organization: #{Organization.count}" 
puts "  - Users: #{User.count}"
puts "  - User Profiles: #{UserProfile.count}"
puts "  - User Groups: #{UserGroup.count}"
puts "  - Spaces: #{Space.count}"
puts "  - Folders: #{Folder.count}"
puts "  - Tags: #{Tag.count}"
puts "  - Documents: #{Document.count}"
puts "  - Immo::Promo Projects: #{Immo::Promo::Project.count}"
puts "  - Dashboard Widgets: #{DashboardWidget.count}"
puts "\n🎭 Professional Users Created:"
puts "  📧 Direction: marie.dubois@meridia.fr, pierre.moreau@meridia.fr"
puts "  👷 Chefs Projet: julien.leroy@meridia.fr, amelie.bernard@meridia.fr"
puts "  🏗️ Technique: francois.moreau@meridia.fr, julie.garnier@meridia.fr"
puts "  💰 Finance: nathalie.giraud@meridia.fr, vincent.roux@meridia.fr"
puts "  ⚖️ Juridique: isabelle.blanc@meridia.fr, alexandre.martin@meridia.fr"
puts "  💼 Commercial: sylvie.dupont@meridia.fr, nicolas.lefevre@meridia.fr"
puts "  🔑 Password pour tous: password123"
puts "\n🏗️ Projets Immobiliers:"
puts "  🏘️ Les Jardins de Belleville (75 logements, Paris 20e)"
puts "  🏢 Résidence Horizon (120 logements, Lyon Part-Dieu)"
puts "  🏢 Business Center Alpha (15000m², La Défense)"