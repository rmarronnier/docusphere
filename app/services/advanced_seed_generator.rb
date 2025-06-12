# Générateur de seeds avancé pour environnement de test réaliste
require 'faker'

class AdvancedSeedGenerator
  attr_reader :organization, :users, :projects, :spaces, :documents, :statistics

  def initialize(options = {})
    @options = {
      users_count: options[:users_count] || 50,
      documents_per_user: options[:documents_per_user] || 20,
      projects_count: options[:projects_count] || 10,
      enable_workflows: options[:enable_workflows] != false,
      enable_notifications: options[:enable_notifications] != false,
      enable_file_download: options[:enable_file_download] != false
    }.freeze
    
    @statistics = {
      users: 0,
      documents: 0,
      projects: 0,
      validations: 0,
      shares: 0,
      notifications: 0,
      start_time: Time.current
    }
    
    @file_downloader = SampleFilesDownloader.new if @options[:enable_file_download]
    @downloaded_files = {}
  end

  def generate!
    puts "\n🚀 Génération d'un environnement de test réaliste pour DocuSphere..."
    puts "=" * 60
    
    begin
      download_sample_files if @options[:enable_file_download]
      create_organization
      create_users
      create_user_groups
      create_spaces_and_folders
      create_projects if defined?(Immo::Promo::Project) && @options[:projects_count] > 0
      create_documents
      create_workflows if @options[:enable_workflows]
      create_shares_and_collaborations
      create_notifications if @options[:enable_notifications]
      create_recent_activity
      cleanup_downloads if @options[:enable_file_download]
      
      display_statistics
    rescue => e
      puts "\n❌ Erreur lors de la génération: #{e.class} - #{e.message}"
      puts "Backtrace:"
      puts e.backtrace.first(15).join("\n")
      cleanup_downloads if @options[:enable_file_download]
      raise
    end
  end

  private

  def download_sample_files
    puts "\n📥 Téléchargement des fichiers d'exemple..."
    @downloaded_files = @file_downloader.download_all
    puts "✅ #{@downloaded_files.values.flatten.count} fichiers téléchargés"
  end

  def create_organization
    puts "\n🏢 Création de l'organisation principale..."
    
    @organization = Organization.find_or_create_by!(name: "Groupe Immobilier Horizon") do |org|
      org.settings = {
        sectors: ["construction", "promotion", "gestion"],
        employees_count: @options[:users_count],
        annual_revenue: "250M€",
        certifications: ["ISO 9001", "ISO 14001", "HQE"],
        subsidiaries: ["Horizon Construction", "Horizon Promotion", "Horizon Gestion"]
      }
    end
    
    puts "✅ Organisation créée: #{@organization.name}"
  end

  def create_users
    puts "\n👥 Création de #{@options[:users_count]} utilisateurs..."
    
    @users = []
    
    # Créer des utilisateurs par département avec au moins 1 de chaque type important
    base_departments = {
      direction: 1,
      chef_projet: 2,
      commercial: 1,
      expert_technique: 1,
      juriste: 1,
      controleur: 1,
      architecte: 1,
      assistant_rh: 1,
      communication: 1
    }
    
    # Calculer le nombre total déjà assigné
    total_assigned = base_departments.values.sum
    
    # Distribuer les utilisateurs restants
    remaining = @options[:users_count] - total_assigned
    if remaining > 0
      # Ajouter les utilisateurs restants proportionnellement
      base_departments[:chef_projet] += (remaining * 0.3).to_i
      base_departments[:commercial] += (remaining * 0.2).to_i
      base_departments[:expert_technique] += (remaining * 0.2).to_i
      base_departments[:direction] += (remaining * 0.1).to_i
      base_departments[:architecte] += (remaining * 0.1).to_i
      base_departments[:juriste] += (remaining * 0.1).to_i
      
      # S'assurer qu'on a exactement le bon nombre
      while @users.count < @options[:users_count] && base_departments.values.sum < @options[:users_count]
        base_departments[:chef_projet] += 1
      end
    end
    
    base_departments.each do |dept, count|
      count.times do
        user_data = RealisticDataGenerator.generate_user
        
        # S'assurer que l'email est unique
        email = user_data[:email]
        counter = 1
        while User.exists?(email: email)
          email = "#{user_data[:first_name].downcase}.#{user_data[:last_name].downcase}#{counter}@#{user_data[:email].split('@').last}"
          counter += 1
        end
        
        user = User.create!(
          email: email,
          password: 'password123',
          password_confirmation: 'password123',
          first_name: user_data[:first_name],
          last_name: user_data[:last_name],
          organization: @organization,
          role: [:user, :manager, :admin].sample,
          confirmed_at: Time.current
        )
        
        # Créer le profil utilisateur
        UserProfile.create!(
          user: user,
          profile_type: dept.to_s,
          preferences: {
            job_title: user_data[:job_title],
            department: dept.to_s,
            phone: user_data[:phone],
            mobile: user_data[:mobile],
            office_location: ["Paris", "Lyon", "Marseille", "Toulouse"].sample,
            years_experience: rand(1..20),
            specializations: generate_specializations(dept)
          }
        )
        
        @users << user
        @statistics[:users] += 1
        
        # Arrêter si on a atteint le nombre souhaité
        break if @users.count >= @options[:users_count]
      end
      
      # Arrêter si on a atteint le nombre souhaité
      break if @users.count >= @options[:users_count]
    end
    
    puts "✅ #{@users.count} utilisateurs créés"
    
    # Afficher quelques comptes de test
    puts "\n📧 Comptes de test créés:"
    @users.first(5).each do |user|
      puts "  - #{user.email} (password: password123) - #{user.active_profile&.profile_type}"
    end
  end

  def create_user_groups
    puts "\n👥 Création des groupes d'utilisateurs..."
    
    groups = [
      { name: "Comité de Direction", users: @users.select { |u| u.active_profile&.profile_type == 'direction' } },
      { name: "Équipe Commerciale", users: @users.select { |u| u.active_profile&.profile_type == 'commercial' } },
      { name: "Bureau d'Études", users: @users.select { |u| u.active_profile&.profile_type == 'expert_technique' } },
      { name: "Service Juridique", users: @users.select { |u| u.active_profile&.profile_type == 'juriste' } },
      { name: "Chefs de Projet", users: @users.select { |u| u.active_profile&.profile_type == 'chef_projet' } },
      { name: "Validation Niveau 1", users: @users.sample([10, @users.count].min) },
      { name: "Validation Niveau 2", users: @users.sample([5, @users.count].min) },
      { name: "Archivage", users: @users.sample([3, @users.count].min) }
    ]
    
    created_count = 0
    groups.each do |group_data|
      next if group_data[:users].empty?
      
      group = UserGroup.find_or_create_by!(
        name: group_data[:name],
        organization: @organization
      ) do |g|
        g.description = "Groupe #{group_data[:name]} - #{group_data[:users].count} membres"
      end
      
      created_count += 1 if group.previously_new_record?
      
      # Supprimer les membres existants pour ce groupe
      UserGroupMembership.where(user_group: group).destroy_all
      
      # Ajouter les nouveaux membres
      group_data[:users].each do |user|
        UserGroupMembership.find_or_create_by!(
          user: user,
          user_group: group
        ) do |m|
          m.role = [:member, :admin].sample
        end
      end
    end
    
    puts "✅ #{created_count} nouveaux groupes créés (#{groups.count} au total)"
  end

  def create_spaces_and_folders
    puts "\n📁 Création de la structure de dossiers..."
    
    @spaces = []
    folder_structure = RealisticDataGenerator.generate_folder_structure
    
    folder_structure.each do |space_name, folders|
      space = Space.find_or_create_by!(
        name: space_name,
        organization: @organization
      ) do |s|
        s.settings = {
          space_type: detect_space_type(space_name),
          created_by_id: @users.sample.id,
          color: ["blue", "green", "purple", "orange", "red"].sample,
          icon: ["folder", "briefcase", "building", "chart", "users"].sample,
          access_level: ["public", "restricted", "private"].sample
        }
      end
      
      @spaces << space
      
      # Créer les dossiers
      folders.each do |folder_name|
        parent_folder = Folder.find_or_create_by!(
          name: folder_name,
          parent: nil,
          space: space
        ) do |f|
          f.description = "Dossier #{folder_name} - #{space_name}"
        end
        
        # Créer quelques sous-dossiers
        rand(0..3).times do |i|
          subfolder_suffix = ['Archives', 'En cours', 'Validé', 'Draft'].sample
          subfolder_name = "#{folder_name} - #{subfolder_suffix} #{i+1}"
          
          Folder.find_or_create_by!(
            name: subfolder_name,
            parent: parent_folder,
            space: space
          )
        end
      end
    end
    
    puts "✅ #{@spaces.count} espaces et leurs dossiers créés"
  end

  def create_projects
    return unless @options[:projects_count] > 0
    
    puts "\n🏗️ Création de #{@options[:projects_count]} projets immobiliers..."
    
    @projects = []
    
    @options[:projects_count].times do
      project_data = RealisticDataGenerator.generate_project
      
      # Génération d'un slug unique
      base_slug = project_data[:name].parameterize
      slug = base_slug
      counter = 1
      while Immo::Promo::Project.exists?(slug: slug, organization: @organization)
        slug = "#{base_slug}-#{counter}"
        counter += 1
      end
      
      # Génération d'un numéro de référence unique
      reference_number = "PROJ-#{Date.today.year}-#{rand(10000..99999)}"
      while Immo::Promo::Project.exists?(reference_number: reference_number)
        reference_number = "PROJ-#{Date.today.year}-#{rand(10000..99999)}"
      end
      
      project = Immo::Promo::Project.create!(
        name: project_data[:name],
        slug: slug,
        reference_number: reference_number,
        project_type: project_data[:type],
        total_budget_cents: project_data[:budget] * 100, # Conversion en centimes
        city: project_data[:city],
        start_date: project_data[:start_date],
        expected_completion_date: project_data[:end_date],
        organization: @organization,
        project_manager: @users.select { |u| u.active_profile&.profile_type == 'chef_projet' }.sample,
        description: project_data[:description],
        buildable_surface_area: rand(1000..50000),
        total_units: rand(10..500),
        address: "#{rand(1..200)} #{['Avenue', 'Boulevard', 'Rue'].sample} #{['Victor Hugo', 'République', 'Foch'].sample}",
        postal_code: "#{rand(10..95)}#{rand(100..999)}",
        country: "France",
        metadata: {
          floors_count: rand(1..30),
          parking_spots: rand(50..500),
          energy_rating: ["A", "B", "C"].sample,
          environmental_certification: ["HQE", "BREEAM", "LEED"].sample
        }
      )
      
      # Créer les phases du projet
      create_project_phases(project)
      
      # Assigner des stakeholders
      assign_project_stakeholders(project)
      
      @projects << project
      @statistics[:projects] += 1
    end
    
    puts "✅ #{@projects.count} projets créés"
  end

  def create_documents
    puts "\n📄 Création des documents..."
    
    @documents = []
    categories = @downloaded_files.keys
    
    # Documents par utilisateur
    @users.each do |user|
      rand(5..@options[:documents_per_user]).times do
        category = categories.sample
        files = @downloaded_files[category] || []
        next if files.empty?
        
        file_path = files.sample
        next unless file_path && File.exist?(file_path)
        
        document = create_document_from_file(file_path, user, category)
        @documents << document if document
      end
    end
    
    # Documents de projet si les projets existent
    if @projects&.any?
      @projects.each do |project|
        rand(10..30).times do
          category = [:pdf, :images, :office, :cad].sample
          files = @downloaded_files[category] || []
          next if files.empty?
          
          file_path = files.sample
          next unless file_path && File.exist?(file_path)
          
          document = create_project_document(file_path, project, category)
          @documents << document if document
        end
      end
    end
    
    puts "✅ #{@documents.count} documents créés"
  end

  def create_document_from_file(file_path, user, category)
    folder = Folder.joins(:space).where(organization: @organization).sample
    return unless folder
    
    name = RealisticDataGenerator.generate_document_name(category)
    
    document = Document.create!(
      title: name,
      description: RealisticDataGenerator.generate_document_description(category, name),
      folder: folder,
      space: folder.space,
      uploaded_by: user,
      document_type: detect_document_type(file_path),
      status: [:draft, :active, :archived].sample,
      metadata: {
        auto_generated: false,
        source: "seed_generator",
        category: category.to_s,
        tags: RealisticDataGenerator.generate_tags
      }
    )
    
    # Attacher le fichier
    document.file.attach(
      io: File.open(file_path),
      filename: File.basename(file_path),
      content_type: detect_content_type(file_path)
    )
    
    # Ajouter des métadonnées dans la colonne JSONB
    if document.document_type
      generated_metadata = RealisticDataGenerator.generate_metadata(document.document_type.to_sym)
      document.update_column(:metadata, document.metadata.merge(generated_metadata))
    end
    
    # Créer quelques tags
    RealisticDataGenerator.generate_tags.each do |tag_name|
      tag = Tag.find_or_create_by!(
        name: tag_name,
        organization: @organization
      )
      
      DocumentTag.create!(
        document: document,
        tag: tag
      )
    end
    
    @statistics[:documents] += 1
    document
  rescue => e
    Rails.logger.error "Erreur création document: #{e.message}"
    nil
  end

  def create_project_document(file_path, project, category)
    user = project.project_manager || @users.sample
    
    document = create_document_from_file(file_path, user, category)
    return unless document
    
    # Lier le document au projet
    document.update!(
      documentable: project,
      document_type: [:permit, :contract, :plan, :report].sample
    )
    
    document
  end

  def create_workflows
    puts "\n⚡ Création des workflows de validation..."
    
    validation_count = 0
    
    # Créer des validations pour certains documents
    @documents.sample(@documents.count / 3).each do |document|
      validation_request = ValidationRequest.create!(
        validatable: document,
        requester: document.uploaded_by,
        due_date: rand(1.day.from_now..2.weeks.from_now),
        description: "Merci de valider ce document #{document.title}",
        status: [:pending, :completed].sample,
        min_validations: rand(1..3)
      )
      
      # Si complété, ajouter une date de complétion
      if validation_request.status == 'completed'
        validation_request.update!(
          completed_at: rand(1.hour.ago..Time.current)
        )
      end
      
      # Créer des validations individuelles
      rand(1..3).times do
        DocumentValidation.create!(
          validation_request: validation_request,
          validatable: document,
          validator: @users.reject { |u| u == document.uploaded_by }.sample,
          status: [:pending, :approved, :rejected].sample,
          comment: ["Conforme aux exigences", "Document validé", "À revoir", "Non conforme"].sample,
          validated_at: validation_request.completed? ? rand(1.day.ago..Time.current) : nil
        )
      end
      
      validation_count += 1
    end
    
    @statistics[:validations] = validation_count
    puts "✅ #{validation_count} workflows de validation créés"
  end

  def create_shares_and_collaborations
    puts "\n🤝 Création des partages et collaborations..."
    
    shares_count = 0
    
    # Partages de documents
    @documents.sample(@documents.count / 4).each do |document|
      share = Share.create!(
        shareable: document,
        shared_by: document.uploaded_by,
        shared_with: @users.reject { |u| u == document.uploaded_by }.sample,
        access_level: [:read, :write, :manage].sample,
        expires_at: [nil, 1.month.from_now, 3.months.from_now].sample
      )
      
      # Partager avec des utilisateurs
      @users.sample(rand(1..5)).each do |user|
        DocumentShare.create!(
          document: document,
          shared_with: user,
          shared_by: share.shared_by,
          access_level: [:read, :write, :manage].sample,
          expires_at: share.expires_at
        )
      end
      
      shares_count += 1
    end
    
    @statistics[:shares] = shares_count
    puts "✅ #{shares_count} partages créés"
  end

  def create_notifications
    puts "\n🔔 Création des notifications..."
    
    notification_types = [
      { type: 'document_shared', title: 'Document partagé avec vous' },
      { type: 'document_validation_requested', title: 'Validation requise' },
      { type: 'document_validation_approved', title: 'Document validé' },
      { type: 'document_processing_completed', title: 'Traitement terminé' },
      { type: 'project_task_assigned', title: 'Tâche assignée' },
      { type: 'project_deadline_approaching', title: 'Échéance proche' }
    ]
    
    @users.each do |user|
      rand(3..10).times do
        notif_type = notification_types.sample
        
        Notification.create!(
          user: user,
          notification_type: notif_type[:type],
          title: notif_type[:title],
          message: generate_notification_message(notif_type[:type]),
          data: {
            document_id: @documents.sample&.id,
            project_id: @projects&.sample&.id,
            sender_id: @users.sample&.id,
            timestamp: Time.current,
            priority: [:low, :normal, :high].sample
          },
          read_at: [nil, nil, nil, rand(1.day.ago..Time.current)].sample,
          created_at: rand(1.week.ago..Time.current)
        )
        
        @statistics[:notifications] += 1
      end
    end
    
    puts "✅ #{@statistics[:notifications]} notifications créées"
  end

  def create_recent_activity
    puts "\n📊 Création de l'activité récente..."
    
    # Audits de documents (utilise paper_trail)
    @documents.sample(@documents.count / 2).each do |document|
      # Simuler des modifications
      rand(1..3).times do
        document.update_column(:updated_at, rand(1.week.ago..Time.current))
        document.update_column(:metadata, document.metadata.merge({ "last_activity" => Time.current.to_s }))
      end
    end
    
    # Recherches récentes
    search_terms = ["contrat", "plan", "rapport", "budget", "permis", "étude", "devis"]
    @users.sample(20).each do |user|
      rand(1..5).times do
        SearchQuery.create!(
          query: search_terms.sample,
          user: user,
          query_params: {
            filters: {
              document_type: ["contract", "plan", "report"].sample,
              date_range: "last_30_days"
            }
          },
          usage_count: rand(1..10),
          last_used_at: rand(1.week.ago..Time.current),
          created_at: rand(1.week.ago..Time.current)
        )
      end
    end
    
    puts "✅ Activité récente créée"
  end

  def cleanup_downloads
    @file_downloader&.cleanup_downloads if @options[:enable_file_download]
  end

  def display_statistics
    duration = Time.current - @statistics[:start_time]
    
    puts "\n" + "=" * 60
    puts "✅ GÉNÉRATION TERMINÉE AVEC SUCCÈS!"
    puts "=" * 60
    puts "\n📊 Statistiques de génération:"
    puts "  - Utilisateurs créés: #{@statistics[:users]}"
    puts "  - Documents créés: #{@statistics[:documents]}"
    puts "  - Projets créés: #{@statistics[:projects]}"
    puts "  - Validations créées: #{@statistics[:validations]}"
    puts "  - Partages créés: #{@statistics[:shares]}"
    puts "  - Notifications créées: #{@statistics[:notifications]}"
    puts "  - Durée totale: #{duration.round(2)} secondes"
    puts "\n🎉 Environnement de test prêt à l'emploi!"
    puts "\n📧 Connexion: Utilisez n'importe quel email créé avec le mot de passe 'password123'"
  end

  # Méthodes utilitaires

  def detect_space_type(name)
    case name.downcase
    when /direction|stratégie/ then 'executive'
    when /projet/ then 'project'
    when /commercial|vente/ then 'sales'
    when /technique|étude/ then 'technical'
    when /juridique|legal/ then 'legal'
    when /finance|compta/ then 'financial'
    when /rh|ressource/ then 'hr'
    when /qualité|iso/ then 'quality'
    when /archive/ then 'archive'
    else 'general'
    end
  end

  def detect_document_type(file_path)
    filename = File.basename(file_path).downcase
    
    case filename
    when /permis|autorisation/ then 'permit'
    when /contrat|accord/ then 'contract'
    when /plan|schema/ then 'plan'
    when /rapport|compte.rendu/ then 'report'
    when /etude|note.calcul/ then 'technical'
    when /budget|facture/ then 'financial'
    when /legal|juridique/ then 'legal'
    else 'other'
    end
  end

  def detect_content_type(file_path)
    ext = File.extname(file_path).downcase
    
    case ext
    when '.pdf' then 'application/pdf'
    when '.jpg', '.jpeg' then 'image/jpeg'
    when '.png' then 'image/png'
    when '.gif' then 'image/gif'
    when '.doc', '.docx' then 'application/msword'
    when '.xls', '.xlsx' then 'application/vnd.ms-excel'
    when '.ppt', '.pptx' then 'application/vnd.ms-powerpoint'
    when '.txt' then 'text/plain'
    when '.zip' then 'application/zip'
    when '.mp4' then 'video/mp4'
    when '.avi' then 'video/x-msvideo'
    else 'application/octet-stream'
    end
  end

  def generate_specializations(department)
    specializations = {
      direction: ["Stratégie", "M&A", "Gouvernance", "Innovation"],
      chef_projet: ["Gestion de projet", "Planning", "Coordination", "BIM"],
      commercial: ["Négociation", "Développement", "Marketing", "CRM"],
      expert_technique: ["Structure", "Fluides", "VRD", "Méthodes", "BIM", "Énergie"],
      juriste: ["Droit construction", "Contrats", "Contentieux", "Urbanisme"],
      controleur: ["Contrôle de gestion", "Audit", "Compliance", "Reporting"],
      architecte: ["Conception", "Design", "Urbanisme", "Patrimoine"],
      assistant_rh: ["Recrutement", "Formation", "Paie", "Administration"],
      communication: ["Digital", "Presse", "Événementiel", "Contenus"],
      admin_system: ["Infrastructure", "Sécurité", "DevOps", "Cloud"]
    }
    
    (specializations[department] || ["Général"]).sample(rand(1..3))
  end

  def create_project_phases(project)
    phases = [
      { name: "Études préliminaires", duration: 2, type: "studies" },
      { name: "Conception", duration: 3, type: "studies" },
      { name: "Permis de construire", duration: 4, type: "permits" },
      { name: "Consultation entreprises", duration: 2, type: "studies" },
      { name: "Travaux - Gros œuvre", duration: 8, type: "construction" },
      { name: "Travaux - Second œuvre", duration: 6, type: "construction" },
      { name: "Finitions", duration: 3, type: "finishing" },
      { name: "Réception", duration: 1, type: "reception" }
    ]
    
    start_date = project.start_date
    
    phases.each_with_index do |phase_data, index|
      phase = Immo::Promo::Phase.create!(
        project: project,
        name: phase_data[:name],
        phase_type: phase_data[:type],
        position: index + 1,
        start_date: start_date,
        end_date: start_date + phase_data[:duration].months,
        status: calculate_phase_status(start_date),
        description: "Phase #{phase_data[:name]} du projet #{project.name}"
      )
      
      start_date = phase.end_date
    end
  end

  def assign_project_stakeholders(project)
    stakeholder_types = [
      { type: "architect", count: 1 },
      { type: "contractor", count: rand(2..4) },
      { type: "engineer", count: rand(1..3) },
      { type: "consultant", count: rand(1..2) },
      { type: "subcontractor", count: rand(2..5) },
      { type: "control_office", count: 1 }
    ]
    
    stakeholder_types.each do |stakeholder_data|
      stakeholder_data[:count].times do
        user_data = RealisticDataGenerator.generate_user
        company_name = RealisticDataGenerator::COMPANY_NAMES.sample
        
        Immo::Promo::Stakeholder.create!(
          project: project,
          name: company_name,
          company_name: company_name,
          stakeholder_type: stakeholder_data[:type],
          role: stakeholder_data[:type].humanize,
          contact_person: "#{user_data[:first_name]} #{user_data[:last_name]}",
          email: user_data[:email],
          phone: RealisticDataGenerator.generate_french_phone,
          address: "#{rand(1..200)} #{['Avenue', 'Boulevard', 'Rue'].sample} #{['Victor Hugo', 'République', 'Foch'].sample}, #{project.city}",
          siret: rand(10000000000000..99999999999999).to_s, # 14 chiffres
          is_active: true,
          is_primary: stakeholder_data[:type] == "architect"
        )
      end
    end
  end

  def calculate_phase_status(start_date)
    if start_date > Date.today
      'pending'
    elsif start_date + 2.months < Date.today
      'completed'
    else
      'in_progress'
    end
  end

  def generate_notification_message(type)
    case type
    when 'document_shared'
      "Un document a été partagé avec vous"
    when 'document_validation_requested'
      "Votre validation est requise pour un document"
    when 'document_validation_approved'
      "Un document a été validé avec succès"
    when 'document_processing_completed'
      "Le traitement d'un document est terminé"
    when 'project_task_assigned'
      "Une nouvelle tâche vous a été assignée"
    when 'project_deadline_approaching'
      "Une échéance approche pour l'une de vos tâches"
    else
      "Nouvelle activité sur DocuSphere"
    end
  end
end