# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Option pour utiliser le nouveau système de seeds avancé
if ENV['USE_ADVANCED_SEED'] == 'true'
  puts "🚀 Utilisation du système de seeds avancé..."
  
  options = {
    users_count: ENV['USERS_COUNT']&.to_i || 50,
    documents_per_user: ENV['DOCS_PER_USER']&.to_i || 20,
    projects_count: ENV['PROJECTS_COUNT']&.to_i || 10,
    enable_workflows: ENV['ENABLE_WORKFLOWS'] != 'false',
    enable_notifications: ENV['ENABLE_NOTIFICATIONS'] != 'false',
    enable_file_download: ENV['DOWNLOAD_FILES'] != 'false'
  }
  
  generator = AdvancedSeedGenerator.new(options)
  generator.generate!
  exit
end

# Allow running specific seed files
if ENV['SEED_TYPE'] == 'essential'
  require_relative 'seeds/essential'
  exit
end

require 'faker'

puts "🌱 Starting comprehensive seed process..."

# Clear existing data in development
if Rails.env.development?
  puts "🧹 Cleaning up existing data..."
  
  # Immo::Promo models - delete in reverse order of dependencies
  # First, delete all records using delete_all to avoid callbacks
  Immo::Promo::TimeLog.delete_all
  Immo::Promo::TaskDependency.delete_all
  Immo::Promo::Task.delete_all
  Immo::Promo::Milestone.delete_all
  Immo::Promo::PhaseDependency.delete_all
  Immo::Promo::Phase.delete_all
  Immo::Promo::PermitCondition.delete_all
  Immo::Promo::Permit.delete_all
  Immo::Promo::ProgressReport.delete_all
  Immo::Promo::Risk.delete_all
  Immo::Promo::Reservation.delete_all
  Immo::Promo::LotSpecification.delete_all
  Immo::Promo::Lot.delete_all
  Immo::Promo::BudgetLine.delete_all
  Immo::Promo::Budget.delete_all
  Immo::Promo::Contract.delete_all
  Immo::Promo::Certification.delete_all
  Immo::Promo::Stakeholder.delete_all
  Immo::Promo::Project.delete_all
  
  # Core models
  WorkflowSubmission.destroy_all
  WorkflowStep.destroy_all
  Workflow.destroy_all
  # Skip ProjectWorkflowStep for now - model mismatch
  # ProjectWorkflowStep.destroy_all
  # ProjectWorkflowTransition.destroy_all
  BasketItem.destroy_all
  Basket.destroy_all
  Authorization.destroy_all
  # DocumentVersion.destroy_all # Using paper_trail instead
  DocumentTag.destroy_all
  Link.destroy_all
  Share.destroy_all
  Metadatum.destroy_all
  Document.destroy_all
  Folder.destroy_all
  Space.destroy_all
  UserGroupMembership.destroy_all
  UserGroup.destroy_all
  Notification.destroy_all
  SearchQuery.destroy_all
  User.destroy_all
  MetadataField.destroy_all
  MetadataTemplate.destroy_all
  Tag.destroy_all
  Organization.destroy_all
end

# Helper method to generate file content
def generate_file_content(file_type)
  case file_type
  when 'pdf'
    # Generate real PDF using Prawn
    require 'prawn'
    Prawn::Document.new do |pdf|
      pdf.text "Document #{Faker::Lorem.sentence}", size: 20, style: :bold
      pdf.move_down 20
      pdf.text "Created on: #{Date.current}", size: 12
      pdf.move_down 20
      pdf.text Faker::Lorem.paragraphs(number: rand(3..6)).join("\n\n"), size: 10
    end.render
  when 'docx', 'doc', 'pptx', 'xlsx', 'xls'
    # For Office documents, create a simple text representation
    # In production, you'd use caracal for docx, axlsx for xlsx, etc.
    content = "Office Document (#{file_type.upcase})\n"
    content += "="*50 + "\n\n"
    content += "Title: #{Faker::Lorem.sentence}\n"
    content += "Author: #{Faker::Name.name}\n"
    content += "Date: #{Date.current}\n\n"
    content += Faker::Lorem.paragraphs(number: rand(5..15)).join("\n\n")
    content
  when 'txt'
    Faker::Lorem.paragraphs(number: rand(5..20)).join("\n\n")
  when 'csv'
    headers = ["ID", "Name", "Date", "Value", "Status"]
    rows = rand(10..50).times.map do |i|
      [i+1, Faker::Company.name, Faker::Date.backward(days: 365), rand(100..10000), ["Active", "Pending", "Closed"].sample]
    end
    ([headers] + rows).map { |row| row.join(",") }.join("\n")
  when 'json'
    {
      id: Faker::Number.unique.number(digits: 6),
      name: Faker::Company.name,
      data: rand(5..10).times.map { { key: Faker::Lorem.word, value: Faker::Lorem.sentence } },
      created_at: Faker::Date.backward(days: 365)
    }.to_json
  when 'xml'
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <document>
        <title>#{Faker::Lorem.sentence}</title>
        <author>#{Faker::Name.name}</author>
        <content>#{Faker::Lorem.paragraphs(number: 3).join(" ")}</content>
        <date>#{Faker::Date.backward(days: 365)}</date>
      </document>
    XML
  when 'svg'
    <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
        <circle cx="50" cy="50" r="40" fill="#{['red', 'blue', 'green', 'yellow', 'purple'].sample}" />
        <text x="50" y="55" text-anchor="middle" fill="white">#{Faker::Lorem.word}</text>
      </svg>
    SVG
  when 'html'
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>#{Faker::Lorem.sentence}</title>
      </head>
      <body>
        <h1>#{Faker::Lorem.sentence}</h1>
        <p>#{Faker::Lorem.paragraphs(number: 3).join("</p><p>")}</p>
      </body>
      </html>
    HTML
  else
    Faker::Lorem.paragraphs(number: rand(3..10)).join("\n\n")
  end
end

# Create organizations
puts "🏢 Creating organizations..."
organizations = []
5.times do |i|
  org = Organization.create!(
    name: Faker::Company.name,
    slug: Faker::Internet.unique.slug(words: nil, glue: '-')
  )
  organizations << org
end

# Add Docusphere as main organization
main_org = Organization.create!(
  name: "Docusphere",
  slug: "docusphere"
)
organizations << main_org

# Create admin user
puts "👤 Creating admin user..."
admin = User.create!(
  email: "admin@docusphere.fr",
  password: "password123",
  password_confirmation: "password123",
  first_name: "Admin",
  last_name: "Système",
  organization: main_org,
  role: "admin"
)

# Create users
puts "👥 Creating 100 users..."
users = [admin]
departments = ["Finance", "RH", "IT", "Marketing", "Direction", "Juridique", "R&D", "Commercial", "Production", "Logistique"]
roles = ["user", "user", "user", "manager", "admin"] # More users than managers/admins

99.times do |i|
  user = User.create!(
    email: Faker::Internet.unique.email,
    password: "password123",
    password_confirmation: "password123",
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    organization: organizations.sample,
    role: roles.sample,
    permissions: roles.sample == "admin" ? ["document:create", "document:delete", "user:manage"] : ["document:create", "document:read"]
  )
  users << user
end

# Create metadata templates
puts "📋 Creating metadata templates..."
metadata_templates = []
organizations.each do |org|
  ["Contract", "Invoice", "Report", "Policy", "Procedure"].each do |template_type|
    template = MetadataTemplate.create!(
      name: "#{template_type} Template",
      description: "Standard template for #{template_type.downcase} documents",
      organization: org
    )
    metadata_templates << template
  end
end

# Create metadata fields
puts "🏷️ Creating metadata fields..."
metadata_fields = []
metadata_templates.each do |template|
  field_types = [
    { name: "Author", field_type: "string", required: true },
    { name: "Department", field_type: "string", required: true },
    { name: "Date", field_type: "date", required: true },
    { name: "Status", field_type: "select", required: false, options: ["Draft", "Review", "Approved", "Published"] },
    { name: "Confidential", field_type: "boolean", required: false },
    { name: "Version", field_type: "string", required: false },
    { name: "Keywords", field_type: "text", required: false }
  ]
  
  field_types.sample(rand(3..5)).each do |field_data|
    field = MetadataField.create!(
      name: field_data[:name],
      field_type: field_data[:field_type],
      required: field_data[:required],
      options: field_data[:options],
      metadata_template: template
    )
    metadata_fields << field
  end
end

# Create user groups
puts "👫 Creating user groups..."
user_groups = []
organizations.each do |org|
  departments.sample(rand(3..7)).each do |dept|
    group = UserGroup.create!(
      name: "#{dept} - #{org.name}",
      description: "Groupe #{dept} de #{org.name}",
      organization: org,
      group_type: ["department", "project", "team"].sample,
      is_active: [true, true, true, false].sample # Most groups are active
    )
    user_groups << group
    
    # Add members to groups
    org_users = users.select { |u| u.organization_id == org.id }
    org_users.sample(rand(2..8)).each do |user|
      UserGroupMembership.create!(
        user: user,
        user_group: group,
        role: ["member", "member", "member", "admin"].sample # More members than admins
      )
    end
  end
end

# Create tags
puts "🏷️ Creating tags..."
tag_categories = {
  status: ["urgent", "important", "archive", "brouillon", "validé", "en-cours", "terminé"],
  confidentiality: ["public", "interne", "confidentiel", "secret"],
  type: ["contrat", "facture", "rapport", "présentation", "procédure", "politique", "formulaire"],
  department: departments
}

tags = []
tag_categories.each do |category, names|
  names.each do |name|
    organizations.each do |org|
      tag = Tag.create!(name: name, organization: org)
      tags << tag
    end
  end
end

# Create spaces
puts "📁 Creating spaces..."
spaces = []
# Define standard spaces for each organization
standard_spaces = [
  { name: "RH", description: "Ressources Humaines - Documents RH, contrats, formations", required: true },
  { name: "Juridique", description: "Documents juridiques, contrats, conformité", required: false },
  { name: "Technique", description: "Documentation technique, guides, procédures", required: false },
  { name: "Commercial", description: "Propositions, contrats clients, marketing", required: false },
  { name: "Documents Généraux", description: "Documents généraux de l'organisation", required: false },
  { name: "Archives", description: "Documents archivés", required: false }
]

organizations.each do |org|
  standard_spaces.each do |space_data|
    space = Space.create!(
      name: "#{space_data[:name]} - #{org.name}",
      description: space_data[:description],
      organization: org
    )
    spaces << space
    
    # Tous les utilisateurs ont accès à l'espace RH
    if space_data[:name] == "RH"
      org.users.each do |user|
        space.authorize_user(user, 'read', granted_by: admin, comment: "Accès RH automatique")
      end
    end
  end
end

# Create folders
puts "📂 Creating folders..."
folders = []
spaces.each do |space|
  # Root folders
  root_folder_names = ["Documents Officiels", "Travail en Cours", "Archives #{Date.current.year}", "Modèles", "Références"]
  root_folder_names.sample(rand(2..4)).each do |folder_name|
    root_folder = Folder.create!(
      name: folder_name,
      description: "#{folder_name} - #{space.name}",
      space: space,
      slug: folder_name.parameterize,
      parent: nil
    )
    folders << root_folder
    
    # Add metadata to folders
    metadata_keys = ["owner", "department", "project_code", "security_level"].sample(rand(0..3))
    metadata_keys.each do |key|
      value = case key
              when "owner" then departments.sample
              when "department" then departments.sample
              when "project_code" then "PROJ-#{rand(1000..9999)}"
              when "security_level" then ["Level 1", "Level 2", "Level 3"].sample
              end
      Metadatum.create!(
        metadatable: root_folder,
        key: key,
        value: value
      )
    end
    
    # Subfolders
    rand(1..3).times do |subfolder_index|
      subfolder_names = ["Q1", "Q2", "Q3", "Q4", "Janvier", "Février", "Mars", "Avril", "Mai", "Juin", 
                        "Projet Alpha", "Projet Beta", "Client A", "Client B", "Internal", "External"]
      subfolder_name = subfolder_names.sample
      subfolder = Folder.create!(
        name: "#{subfolder_name} #{subfolder_index + 1}",
        description: "Sous-dossier de #{root_folder.name}",
        space: space,
        slug: "#{root_folder.slug}-#{subfolder_name.parameterize}-#{subfolder_index + 1}",
        parent: root_folder
      )
      folders << subfolder
      
      # Sub-subfolders (occasionally)
      if rand < 0.3
        subsubfolder = Folder.create!(
          name: ["Final", "Draft", "Review", "Approved"].sample,
          space: space,
          slug: "#{subfolder.slug}-#{['final', 'draft', 'review', 'approved'].sample}",
          parent: subfolder
        )
        folders << subsubfolder
      end
    end
  end
end

# Project workflow steps will be created within projects context

# Create workflows
puts "🔄 Creating workflows..."
workflows = []
organizations.each do |org|
  ["Document Approval", "Contract Review", "Policy Update", "Expense Approval"].each do |workflow_name|
    workflow = Workflow.create!(
      name: workflow_name,
      description: "#{workflow_name} workflow for #{org.name}",
      organization: org,
      workflow_type: ["approval", "review", "validation"].sample
    )
    workflows << workflow
    
    # Create workflow steps
    step_names = ["Initial Review", "Manager Approval", "Legal Review", "Final Approval", "Archive"]
    step_names.sample(rand(3..5)).each_with_index do |step_name, index|
      WorkflowStep.create!(
        workflow: workflow,
        name: step_name,
        description: "Step #{index + 1}: #{step_name}",
        position: index + 1,
        assigned_to: org.users.sample,
        step_type: ["manual", "automatic", "conditional", "parallel"].sample,
        validation_rules: { min_reviewers: rand(1..3) },
        requires_approval: ["approval"].include?(step_name.downcase),
        priority: ["low", "medium", "high"].sample
      )
    end
  end
end

# Create documents
puts "📄 Creating 300 documents..."
document_types = {
  'application/pdf' => { extensions: ['pdf'], weight: 25 },
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document' => { extensions: ['docx'], weight: 20 },
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' => { extensions: ['xlsx'], weight: 15 },
  'application/vnd.openxmlformats-officedocument.presentationml.presentation' => { extensions: ['pptx'], weight: 10 },
  'application/vnd.ms-word' => { extensions: ['doc'], weight: 5 },
  'application/vnd.ms-excel' => { extensions: ['xls'], weight: 5 },
  'image/jpeg' => { extensions: ['jpg', 'jpeg'], weight: 8 },
  'image/png' => { extensions: ['png'], weight: 6 },
  'image/gif' => { extensions: ['gif'], weight: 2 },
  'image/svg+xml' => { extensions: ['svg'], weight: 1 },
  'text/plain' => { extensions: ['txt'], weight: 1.5 },
  'text/csv' => { extensions: ['csv'], weight: 0.8 },
  'application/json' => { extensions: ['json'], weight: 0.4 },
  'application/xml' => { extensions: ['xml'], weight: 0.3 }
}

# Calculate total weight for weighted random selection
total_weight = document_types.values.sum { |v| v[:weight] }

documents = []
# Generate documents
300.times do |i|
  # Weighted random selection of document type
  random_weight = rand * total_weight
  current_weight = 0
  selected_type = nil
  selected_info = nil
  
  document_types.each do |mime_type, info|
    current_weight += info[:weight]
    if random_weight <= current_weight
      selected_type = mime_type
      selected_info = info
      break
    end
  end
  
  extension = selected_info[:extensions].sample
  
  # Create document
  document_title = "#{Faker::Lorem.words(number: rand(2..5)).join(' ').capitalize}"
  document = Document.new(
    title: document_title,
    description: [Faker::Lorem.sentence, nil, nil].sample, # Some documents don't have descriptions
    uploaded_by: users.sample,
    space: spaces.sample,
    folder: [nil, *folders].sample, # Some documents are not in folders
    status: ["draft", "published", "locked", "archived"].sample
  )
  
  # Attach file with content based on type
  file_content = if selected_type.include?('image')
    # For images, we'll use Prawn to generate a simple PDF that acts as a placeholder
    # In production, you'd use proper image generation libraries
    case extension
    when 'png', 'jpg', 'jpeg', 'gif'
      # Generate a simple text file as placeholder
      # In production, you could use ChunkyPNG for PNG, mini_magick for other formats
      "This is a placeholder for #{extension.upcase} image file.\n#{Faker::Lorem.paragraph}"
    when 'svg'
      generate_file_content('svg')
    end
  else
    generate_file_content(extension)
  end
  
  document.file.attach(
    io: StringIO.new(file_content),
    filename: "#{document_title.parameterize}.#{extension}",
    content_type: selected_type
  )
  
  if document.save
    documents << document
    
    # Add tags
    document.tags << tags.sample(rand(1..5))
    
    # Add document metadata
    if rand < 0.3 # 30% of documents have structured metadata
      template = metadata_templates.sample
      template.metadata_fields.each do |field|
        next if !field.required && rand < 0.5 # Skip optional fields sometimes
        
        value = case field.field_type
                when 'string' then Faker::Lorem.word
                when 'text' then Faker::Lorem.paragraph
                when 'date' then Faker::Date.backward(days: 365).to_s
                when 'datetime' then Faker::Time.backward(days: 365).to_s
                when 'boolean' then [true, false].sample.to_s
                when 'select' then field.options&.sample || 'default'
                else Faker::Lorem.word
                end
        
        Metadatum.create!(
          metadatable: document,
          metadata_field: field,
          key: field.name,
          value: value
        )
      end
    end
    
    # Add polymorphic metadata
    metadata_keys = ["project_code", "client_id", "invoice_number", "contract_ref", "approval_date"].sample(rand(0..3))
    metadata_keys.each do |key|
      value = case key
              when "project_code" then "PROJ-#{rand(1000..9999)}"
              when "client_id" then "CLI-#{rand(100..999)}"
              when "invoice_number" then "INV-#{Date.current.year}-#{rand(10000..99999)}"
              when "contract_ref" then "CTR-#{('A'..'Z').to_a.sample(3).join}-#{rand(100..999)}"
              when "approval_date" then Faker::Date.backward(days: 30).to_s
              end
      Metadatum.create!(
        metadatable: document,
        key: key,
        value: value
      )
    end
    
    # Paper_trail will handle document versioning automatically
    
    # Create shares for some documents
    if rand < 0.15 # 15% of documents are shared
      rand(1..3).times do
        share_user = users.sample
        Share.create!(
          shareable: document,
          shared_with: share_user,
          shared_by: document.uploaded_by,
          access_level: ["read", "read", "write", "admin"].sample,
          expires_at: [nil, nil, nil, rand(1..90).days.from_now].sample
        )
        
      end
    end
    
    # Create document links
    if rand < 0.05 && documents.count > 10 # 5% of documents have links
      Link.create!(
        source: document,
        target: documents.sample,
        link_type: ["reference", "related", "parent", "child", "version"].sample
      )
    end
    
    # Add to workflows
    # if rand < 0.1 # 10% of documents in workflows
    #   workflow = workflows.sample
    #   WorkflowSubmission.create!(
    #     workflow: workflow,
    #     submittable: document,
    #     submitted_by: document.uploaded_by,
    #     current_step: workflow.workflow_steps.first,
    #     status: ["pending", "in_progress", "completed", "rejected"].sample
    #   )
    # end
    
    # Create authorizations
    if rand < 0.2 # 20% of documents have specific authorizations
      rand(1..3).times do
        # Choisir soit un utilisateur soit un groupe, pas les deux
        if rand < 0.7 # 70% des autorisations pour les utilisateurs
          selected_user = users.sample
          Authorization.find_or_create_by!(
            authorizable: document,
            user: selected_user,
            user_group: nil
          ) do |auth|
            auth.permission_level = ["read", "write", "admin"].sample
            auth.granted_by = users.sample
          end
        else # 30% pour les groupes
          selected_group = user_groups.sample
          Authorization.find_or_create_by!(
            authorizable: document,
            user: nil,
            user_group: selected_group
          ) do |auth|
            auth.permission_level = ["read", "write", "admin"].sample
            auth.granted_by = users.sample
          end
        end
      end
    end
  end
  
  # Show progress
  if (i + 1) % 100 == 0
    print "."
    print " #{i + 1} documents created\n" if (i + 1) % 1000 == 0
  end
end

# Create baskets
puts "\n🛒 Creating baskets..."
users.sample(20).each do |user|
  basket = Basket.create!(
    name: ["Mes documents", "À traiter", "En cours", "Archives", "Favoris"].sample,
    description: Faker::Lorem.sentence,
    user: user,
    is_shared: [true, false, false].sample # Most baskets are private
  )
  
  # Add items to basket
  basket_documents = documents.sample(rand(3..15))
  basket_documents.each_with_index do |doc, index|
    BasketItem.create!(
      basket: basket,
      item: doc,
      position: index + 1,
      notes: rand < 0.3 ? Faker::Lorem.sentence : nil
    )
  end
end

# Create notifications
puts "🔔 Creating notifications..."
users.each do |user|
  rand(0..10).times do
    notification_types = ["document_shared", "document_validation_requested", "authorization_granted", "document_processing_completed", "system_announcement"]
    notification_type = notification_types.sample
    
    title = case notification_type
            when "document_shared" then "Document partagé"
            when "document_validation_requested" then "Validation demandée"
            when "authorization_granted" then "Autorisation accordée"
            when "document_processing_completed" then "Traitement terminé"
            when "system_announcement" then "Annonce système"
            end
    
    Notification.create!(
      user: user,
      notification_type: notification_type,
      title: title,
      message: Faker::Lorem.sentence,
      read_at: [nil, nil, Time.current].sample, # Most notifications unread
      notifiable: documents.sample,
      data: {
        document_id: documents.sample.id,
        from_user: users.sample.email
      }
    )
  end
end

# Create search queries
puts "🔍 Creating search queries..."
users.sample(30).each do |user|
  rand(1..5).times do
    SearchQuery.create!(
      user: user,
      name: Faker::Lorem.words(number: rand(1..3)).join(' '),
      query_params: {
        q: Faker::Lorem.words(number: rand(1..3)).join(' '),
        filters: {
          document_type: ["pdf", "docx", "xlsx", nil].sample,
          date_range: ["last_week", "last_month", "last_year", nil].sample
        }
      },
      usage_count: rand(0..50),
      last_used_at: rand < 0.7 ? Faker::Time.backward(days: 30) : nil,
      is_favorite: rand < 0.2
    )
  end
end

# Create Immo::Promo data
puts "🏗️ Creating Immo::Promo projects..."
  

# Create projects
projects = []
organizations.each do |org|
  rand(2..5).times do
    project = Immo::Promo::Project.create!(
      name: "#{['Résidence', 'Immeuble', 'Complexe', 'Tour'].sample} #{Faker::Address.community}",
      description: Faker::Lorem.paragraph(sentence_count: 3),
      organization: org,
      project_type: ["residential", "commercial", "mixed", "office", "retail"].sample,
      status: ["planning", "pre_construction", "construction", "finishing", "delivered"].sample,
      address: Faker::Address.full_address,
      city: Faker::Address.city,
      postal_code: Faker::Address.zip_code,
      total_area: rand(1000..50000),
      total_units: rand(10..200),
      start_date: Faker::Date.backward(days: 365),
      expected_completion_date: Faker::Date.forward(days: 730),
      project_manager: org.users.where(role: ["admin", "manager"]).sample || org.users.first,
      land_area: rand(500..10000),
      building_permit_number: "PC-#{Date.current.year}-#{rand(1000..9999)}",
      total_budget_cents: rand(100_000_00..200_000_000), # 100k to 2M euros in cents  
      current_budget_cents: rand(10_000_00..50_000_000) # 10k to 500k euros in cents
    )
    projects << project
    
    # Create stakeholders for this project
    rand(3..8).times do
      stakeholder = Immo::Promo::Stakeholder.create!(
        project: project,
        name: Faker::Company.name,
        stakeholder_type: ["architect", "contractor", "subcontractor", "consultant", "control_office"].sample,
        contact_person: Faker::Name.name,
        email: Faker::Internet.email,
        phone: Faker::PhoneNumber.phone_number,
        address: Faker::Address.full_address,
        specialization: ["Construction", "Architecture", "Engineering", "Legal", "Finance", "Marketing"].sample,
        is_active: [true, true, true, false].sample,
        role: ["main_contractor", "architect", "subcontractor", "consultant", "supplier"].sample
      )
      
      # Add certifications
      rand(0..3).times do
        Immo::Promo::Certification.create!(
          stakeholder: stakeholder,
          name: ["ISO 9001", "ISO 14001", "LEED", "HQE", "BREEAM", "Qualibat"].sample,
          certification_type: ["insurance", "qualification", "rge", "environmental"].sample,
          issuing_body: Faker::Company.name,
          issue_date: Faker::Date.backward(days: 730),
          expiry_date: Faker::Date.forward(days: 365),
          is_verified: [true, true, false].sample
        )
      end
    end
    
    # Create permits
    ["construction", "demolition", "environmental", "urban_planning"].sample(rand(1..3)).each do |permit_type|
      permit = Immo::Promo::Permit.create!(
        project: project,
        permit_type: permit_type,
        permit_number: "#{permit_type.upcase}-#{Date.current.year}-#{rand(1000..9999)}",
        status: ["draft", "submitted", "approved", "denied", "under_review"].sample,
        submitted_date: Faker::Date.backward(days: 180),
        approved_date: ["approved", "expired"].include?(Immo::Promo::Permit.last&.status) ? Faker::Date.backward(days: 90) : nil,
        expiry_date: Faker::Date.forward(days: 365),
        issuing_authority: "#{Faker::Address.city} Municipality",
        notes: Faker::Lorem.sentence
      )
      
      # Add permit conditions
      if permit.status == "approved"
        rand(1..3).times do
          Immo::Promo::PermitCondition.create!(
            permit: permit,
            description: Faker::Lorem.sentence,
            condition_type: ["suspensive", "prescriptive", "information", "technical", "environmental"].sample,
            compliance_status: ["pending", "in_progress", "compliant", "non_compliant"].sample,
            due_date: Faker::Date.forward(days: 90)
          )
        end
      end
    end
    
    # Create phases
    phase_types = ["studies", "permits", "construction", "reception", "delivery"]
    phase_types.each_with_index do |phase_type, index|
      phase = Immo::Promo::Phase.create!(
        project: project,
        name: "Phase #{index + 1}: #{phase_type.capitalize}",
        phase_type: phase_type,
        status: index == 0 ? "in_progress" : "pending",
        start_date: project.start_date + (index * 3).months,
        end_date: project.start_date + ((index + 1) * 3).months,
        progress_percentage: index == 0 ? rand(10..60) : 0,
        is_critical: ["construction", "permits"].include?(phase_type),
        position: index + 1
      )
      
      # Create phase dependencies
      if index > 0
        previous_phases = project.phases.reload.to_a
        if previous_phases.size >= index
          Immo::Promo::PhaseDependency.create!(
            dependent_phase: phase,
            prerequisite_phase: previous_phases[index - 1],
            dependency_type: "finish_to_start"
          )
        end
      end
      
      # Create milestones
      rand(2..4).times do |m_index|
        Immo::Promo::Milestone.create!(
          phase: phase,
          name: "#{phase_type.capitalize} Milestone #{m_index + 1}",
          description: Faker::Lorem.sentence,
          milestone_type: ["permit_submission", "permit_approval", "construction_start", "construction_completion", "delivery", "legal_deadline"].sample,
          target_date: phase.start_date + rand(10..80).days,
          actual_date: phase.status == "completed" ? phase.start_date + rand(10..80).days : nil,
          status: phase.status == "completed" ? "completed" : ["pending", "in_progress"].sample,
          is_critical: rand < 0.3
        )
      end
      
      # Create tasks
      rand(5..15).times do |t_index|
        task = Immo::Promo::Task.create!(
          phase: phase,
          name: "Task #{t_index + 1}: #{Faker::Lorem.words(number: 3).join(' ')}",
          description: Faker::Lorem.sentence,
          task_type: ["administrative", "technical", "financial", "legal", "quality_control"].sample,
          status: phase.status == "in_progress" ? ["pending", "in_progress", "completed"].sample : "pending",
          priority: ["low", "medium", "high", "critical"].sample,
          start_date: phase.start_date + rand(0..30).days,
          end_date: phase.start_date + rand(31..60).days,
          estimated_hours: rand(4..40),
          actual_hours: phase.status == "in_progress" ? rand(0..30) : 0,
          assigned_to: org.users.sample,
          progress_percentage: phase.status == "in_progress" ? rand(0..100) : 0
        )
        
        # Create task dependencies
        if t_index > 0 && rand < 0.3
          existing_tasks = phase.tasks.reload.to_a
          if existing_tasks.size > 1
            Immo::Promo::TaskDependency.create!(
              dependent_task: task,
              prerequisite_task: existing_tasks[rand(0..(existing_tasks.size-2))],
              dependency_type: "finish_to_start"
            )
          end
        end
        
        # Create time logs
        if task.status == "in_progress" && task.assigned_to
          rand(1..5).times do
            Immo::Promo::TimeLog.create!(
              task: task,
              user: task.assigned_to,
              hours: rand(1..8),
              log_date: Faker::Date.between(from: task.start_date, to: Date.current),
              description: Faker::Lorem.sentence
            )
          end
        end
      end
    end
    
    # Create budgets
    budget = Immo::Promo::Budget.create!(
      project: project,
      name: "Budget #{project.name}",
      version: "v1.0",
      budget_type: "initial",
      fiscal_year: Date.current.year,
      total_amount: project.total_budget,
      status: "active"
    )
    
    # Create budget lines
    ["Labor", "Materials", "Equipment", "Subcontractors", "Permits", "Marketing", "Contingency"].each do |category|
      Immo::Promo::BudgetLine.create!(
        budget: budget,
        category: category,
        description: "#{category} costs for #{project.name}",
        planned_amount_cents: rand(5_000_000..200_000_000),
        actual_amount_cents: project.status == "construction" ? rand(3_000_000..150_000_000) : 0,
        committed_amount_cents: rand(2_000_000..100_000_000)
      )
    end
    
    # Create lots
    if ["residential", "mixed"].include?(project.project_type)
      rand(10..50).times do |lot_index|
        lot = Immo::Promo::Lot.create!(
          project: project,
          lot_number: "#{('A'..'E').to_a.sample}#{lot_index + 1}",
          lot_type: ["apartment", "parking", "storage", "commercial"].sample,
          floor: ["apartment", "commercial"].include?(Immo::Promo::Lot.last&.lot_type) ? rand(0..10) : -1,
          surface_area: case Immo::Promo::Lot.last&.lot_type
                        when "apartment" then rand(30..150)
                        when "parking" then rand(12..15)
                        when "storage" then rand(3..10)
                        when "commercial" then rand(50..300)
                        else rand(20..100)
                        end,
          price_cents: rand(10_000_00..10_000_000), # 10k to 100k euros
          status: ["available", "reserved", "sold", "blocked"].sample,
          orientation: ["north", "south", "east", "west", "north-east", "north-west", "south-east", "south-west"].sample
        )
        
        # Create lot specifications
        if lot.lot_type == "apartment"
          Immo::Promo::LotSpecification.create!(
            lot: lot,
            rooms: rand(1..5),
            bedrooms: rand(0..4),
            bathrooms: rand(1..3),
            has_balcony: rand < 0.5,
            has_terrace: rand < 0.3,
            has_parking: rand < 0.7,
            has_storage: rand < 0.6,
            energy_class: ["A", "B", "C", "D", "E"].sample,
            accessibility_features: rand < 0.2
          )
        end
        
        # Create reservations
        if ["reserved", "sold"].include?(lot.status)
          Immo::Promo::Reservation.create!(
            lot: lot,
            client_name: Faker::Name.name,
            client_email: Faker::Internet.email,
            client_phone: Faker::PhoneNumber.phone_number,
            reservation_date: Faker::Date.backward(days: 90),
            expiry_date: lot.status == "reserved" ? Faker::Date.forward(days: 30) : nil,
            deposit_amount_cents: lot.price_cents * 0.1,
            status: lot.status == "sold" ? "converted" : "active",
            notes: Faker::Lorem.sentence
          )
        end
      end
    end
    
    # Create risks
    rand(3..8).times do
      Immo::Promo::Risk.create!(
        project: project,
        category: ["financial", "technical", "legal", "environmental", "schedule", "quality"].sample,
        description: Faker::Lorem.sentence,
        probability: ["low", "medium", "high"].sample,
        impact: ["low", "medium", "high", "critical"].sample,
        status: ["identified", "analyzing", "mitigating", "monitoring", "closed"].sample,
        mitigation_plan: Faker::Lorem.paragraph,
        owner: project.project_manager,
        identified_date: Faker::Date.backward(days: 60),
        target_resolution_date: Faker::Date.forward(days: 30)
      )
    end
    
    # Create progress reports
    rand(2..5).times do
      Immo::Promo::ProgressReport.create!(
        project: project,
        report_date: Faker::Date.backward(days: 30),
        period_start: Faker::Date.backward(days: 37),
        period_end: Faker::Date.backward(days: 30),
        overall_progress: project.phases.average(:progress_percentage) || 0,
        budget_consumed: rand(10..80),
        key_achievements: Faker::Lorem.paragraph,
        issues_risks: Faker::Lorem.paragraph,
        next_period_goals: Faker::Lorem.paragraph,
        prepared_by: project.project_manager
      )
    end
    
    # Create contracts with stakeholders
    project.stakeholders.each do |stakeholder|
      Immo::Promo::Contract.create!(
        stakeholder: stakeholder,
        project: project,
        contract_number: "CTR-#{Date.current.year}-#{rand(10000..99999)}",
        contract_type: ["service", "supply", "construction", "consultation"].sample,
        description: "Contract for #{stakeholder.role} services",
        start_date: project.start_date,
        end_date: project.expected_completion_date,
        amount_cents: rand(500_000..20_000_000), # 5k to 200k euros
        currency: "EUR",
        payment_terms: ["30_days", "60_days", "milestone_based", "monthly"].sample,
        status: ["draft", "active", "completed", "terminated"].sample,
        signed_date: ["active", "completed"].include?(Immo::Promo::Contract.last&.status) ? project.start_date + rand(1..10).days : nil
      )
    end
  end
end

# Final statistics
puts "\n✅ Seed completed!"
puts "📊 Summary:"
puts "  - Organizations: #{Organization.count}"
puts "  - Users: #{User.count} (including admin@docusphere.fr)"
puts "  - User Groups: #{UserGroup.count}"
puts "  - User Group Memberships: #{UserGroupMembership.count}"
puts "  - Spaces: #{Space.count}"
puts "  - Folders: #{Folder.count}"
puts "  - Documents: #{Document.count}"
puts "  - Document Versions (Paper Trail): #{PaperTrail::Version.where(item_type: 'Document').count}"
puts "  - Metadata (structured): #{Metadatum.structured.count}"
puts "  - Metadata (flexible): #{Metadatum.flexible.count}"
puts "  - Metadata (total): #{Metadatum.count}"
puts "  - Tags: #{Tag.count}"
puts "  - Document Tags: #{DocumentTag.count}"
puts "  - Shares: #{Share.count}"
puts "  - Links: #{Link.count}"
# puts "  - Project Workflow Steps: #{ProjectWorkflowStep.count}"
# puts "  - Project Workflow Transitions: #{ProjectWorkflowTransition.count}"
puts "  - Workflows: #{Workflow.count}"
puts "  - Workflow Steps: #{WorkflowStep.count}"
puts "  - Workflow Submissions: #{WorkflowSubmission.count}"
puts "  - Baskets: #{Basket.count}"
puts "  - Basket Items: #{BasketItem.count}"
puts "  - Authorizations: #{Authorization.count}"
puts "  - Notifications: #{Notification.count}"
puts "  - Search Queries: #{SearchQuery.count}"
puts "  - Metadata Templates: #{MetadataTemplate.count}"
puts "  - Metadata Fields: #{MetadataField.count}"
puts "\n🏗️ Immo::Promo Summary:"
puts "  - Projects: #{Immo::Promo::Project.count}"
puts "  - Stakeholders: #{Immo::Promo::Stakeholder.count}"
puts "  - Phases: #{Immo::Promo::Phase.count}"
puts "  - Tasks: #{Immo::Promo::Task.count}"
puts "  - Milestones: #{Immo::Promo::Milestone.count}"
puts "  - Permits: #{Immo::Promo::Permit.count}"
puts "  - Lots: #{Immo::Promo::Lot.count}"
puts "  - Reservations: #{Immo::Promo::Reservation.count}"
puts "  - Budgets: #{Immo::Promo::Budget.count}"
puts "  - Contracts: #{Immo::Promo::Contract.count}"
puts "  - Risks: #{Immo::Promo::Risk.count}"
puts "\n🔐 Login: admin@docusphere.fr / password123"