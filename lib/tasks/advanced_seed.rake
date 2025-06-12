namespace :seed do
  desc "Génère un environnement de test complet avec données réalistes"
  task advanced: :environment do
    puts "\n🚀 Lancement de la génération avancée de données de test..."
    
    # Vérifier l'environnement
    if Rails.env.production?
      puts "⚠️  ATTENTION: Vous êtes en environnement PRODUCTION!"
      print "Êtes-vous sûr de vouloir continuer? (yes/no): "
      response = STDIN.gets.chomp.downcase
      exit unless response == 'yes'
    end
    
    # Options de génération
    options = {
      users_count: ENV['USERS_COUNT']&.to_i || 50,
      documents_per_user: ENV['DOCS_PER_USER']&.to_i || 20,
      projects_count: ENV['PROJECTS_COUNT']&.to_i || 10,
      enable_workflows: ENV['ENABLE_WORKFLOWS'] != 'false',
      enable_notifications: ENV['ENABLE_NOTIFICATIONS'] != 'false',
      enable_file_download: ENV['DOWNLOAD_FILES'] != 'false'
    }
    
    puts "\n📋 Configuration:"
    puts "  - Nombre d'utilisateurs: #{options[:users_count]}"
    puts "  - Documents par utilisateur: #{options[:documents_per_user]}"
    puts "  - Nombre de projets: #{options[:projects_count]}"
    puts "  - Workflows activés: #{options[:enable_workflows] ? 'Oui' : 'Non'}"
    puts "  - Notifications activées: #{options[:enable_notifications] ? 'Oui' : 'Non'}"
    puts "  - Téléchargement fichiers: #{options[:enable_file_download] ? 'Oui' : 'Non'}"
    
    # Lancer la génération
    generator = AdvancedSeedGenerator.new(options)
    generator.generate!
  end

  desc "Télécharge uniquement les fichiers d'exemple"
  task download_samples: :environment do
    puts "\n📥 Téléchargement des fichiers d'exemple..."
    
    downloader = SampleFilesDownloader.new
    files = downloader.download_all
    
    puts "\n📊 Résumé des téléchargements:"
    files.each do |category, file_list|
      puts "  #{category}: #{file_list.count} fichiers"
    end
  end

  desc "Génère un petit jeu de données pour tests rapides"
  task quick: :environment do
    puts "\n⚡ Génération rapide de données de test..."
    
    options = {
      users_count: 10,
      documents_per_user: 5,
      projects_count: 3,
      enable_workflows: true,
      enable_notifications: true,
      enable_file_download: false
    }
    
    generator = AdvancedSeedGenerator.new(options)
    generator.generate!
  end

  desc "Génère un environnement de démonstration commerciale"
  task demo: :environment do
    puts "\n🎯 Génération d'un environnement de démonstration..."
    
    # Nettoyer d'abord les données existantes
    puts "🧹 Nettoyage des données existantes..."
    Document.destroy_all
    DocumentTag.destroy_all
    DocumentShare.destroy_all
    DocumentValidation.destroy_all
    ValidationRequest.destroy_all
    Share.destroy_all
    Notification.destroy_all
    
    # Créer des données de démo simplifiées
    org = Organization.first || Organization.create!(
      name: "Demo Organization",
      settings: { demo: true }
    )
    
    # Créer quelques utilisateurs de test
    users = []
    5.times do |i|
      user = User.find_or_create_by!(email: "demo#{i+1}@example.com") do |u|
        u.password = 'password123'
        u.first_name = ["Alice", "Bob", "Charlie", "David", "Eve"][i]
        u.last_name = "Demo"
        u.organization = org
        u.role = i == 0 ? :admin : :user
        u.confirmed_at = Time.current
      end
      
      UserProfile.find_or_create_by!(user: user) do |p|
        p.profile_type = [:direction, :chef_projet, :commercial, :expert_technique, :juriste][i]
        p.preferences = { demo: true }
      end
      
      users << user
    end
    
    # Créer un espace et des dossiers
    space = Space.find_or_create_by!(
      name: "Espace Demo",
      organization: org
    ) do |s|
      s.settings = { demo: true }
    end
    
    folder = Folder.find_or_create_by!(
      name: "Documents Demo",
      space: space
    )
    
    # Créer quelques documents avec des fichiers simulés
    puts "📄 Création de documents de démonstration..."
    document_types = %w[contract plan report permit technical]
    
    10.times do |i|
      # Créer un fichier temporaire pour attacher
      temp_file = Tempfile.new(["demo_#{i+1}", ".pdf"])
      temp_file.write("Contenu du document de démonstration #{i+1}")
      temp_file.rewind
      
      doc = Document.new(
        title: "Document Demo #{i+1}",
        description: "Document de démonstration numéro #{i+1}",
        folder: folder,
        space: space,
        uploaded_by: users.sample,
        document_type: document_types.sample
      )
      
      # Attacher le fichier avant de sauvegarder
      doc.file.attach(
        io: temp_file,
        filename: "demo_document_#{i+1}.pdf",
        content_type: "application/pdf"
      )
      
      doc.save!
      
      # Publier certains documents
      doc.publish! if i % 2 == 0
      
      # Mettre à jour la colonne metadata JSONB après création
      doc.update_column(:metadata, {
        demo: true,
        created_for: "demo",
        index: i+1
      })
      
      temp_file.close
      temp_file.unlink
      
      # Ajouter quelques tags
      tag_names = ["urgent", "demo", "test", "draft", "final"].sample(2)
      tag_names.each do |tag_name|
        tag = Tag.find_or_create_by!(name: tag_name, organization: org)
        DocumentTag.create!(document: doc, tag: tag)
      end
    end
    
    puts "✅ 10 documents de démonstration créés"
    
    # Créer quelques notifications
    puts "🔔 Création de notifications..."
    users.each do |user|
      3.times do
        Notification.create!(
          user: user,
          notification_type: [:document_shared, :document_validation_requested, :system_announcement].sample,
          title: "Notification de démonstration",
          message: "Ceci est une notification de démonstration pour #{user.first_name}",
          data: { demo: true }
        )
      end
    end
    
    puts "✅ Notifications créées"
    
    puts "\n🎉 Données de démonstration créées avec succès!"
    puts "\nComptes de test:"
    users.each do |user|
      puts "  - #{user.email} (password: password123) - #{user.active_profile&.profile_type}"
    end
  end

  desc "Nettoie les fichiers temporaires de seed"
  task cleanup: :environment do
    puts "\n🧹 Nettoyage des fichiers temporaires..."
    
    temp_dir = Rails.root.join('tmp', 'sample_files')
    if Dir.exist?(temp_dir)
      FileUtils.rm_rf(temp_dir)
      puts "✅ Dossier #{temp_dir} supprimé"
    else
      puts "ℹ️  Aucun fichier temporaire à nettoyer"
    end
  end

  desc "Affiche les statistiques de la base de données"
  task stats: :environment do
    puts "\n📊 Statistiques de la base de données DocuSphere"
    puts "=" * 50
    
    stats = {
      "Organisations" => Organization.count,
      "Utilisateurs" => User.count,
      "Documents" => Document.count,
      "Espaces" => Space.count,
      "Dossiers" => Folder.count,
      "Validations" => ValidationRequest.count,
      "Partages" => Share.count,
      "Notifications" => Notification.count
    }
    
    if defined?(Immo::Promo::Project)
      stats["Projets ImmoPromo"] = Immo::Promo::Project.count
      stats["Phases"] = Immo::Promo::Phase.count
      stats["Intervenants"] = Immo::Promo::Stakeholder.count
    end
    
    stats.each do |label, count|
      puts sprintf("  %-20s : %6d", label, count)
    end
    
    # Statistiques supplémentaires
    puts "\n📈 Statistiques d'utilisation:"
    puts "  Documents avec fichiers: #{Document.joins(:file_attachment).count}"
    puts "  Documents taggés: #{DocumentTag.distinct.count(:document_id)}"
    puts "  Utilisateurs actifs: #{User.where('last_sign_in_at > ?', 1.month.ago).count}"
    
    if Document.any?
      puts "\n📁 Types de fichiers:"
      Document.joins(:file_blob).group('active_storage_blobs.content_type').count.each do |type, count|
        puts sprintf("  %-30s : %4d", type, count)
      end
    end
  end

  desc "Réinitialise complètement la base et génère des données avancées"
  task reset_and_seed: :environment do
    puts "\n⚠️  ATTENTION: Cette commande va SUPPRIMER toutes les données!"
    print "Êtes-vous sûr de vouloir continuer? (yes/no): "
    response = STDIN.gets.chomp.downcase
    exit unless response == 'yes'
    
    puts "\n🔄 Réinitialisation de la base de données..."
    
    # Reset de la base
    Rake::Task['db:drop'].invoke
    Rake::Task['db:create'].invoke
    Rake::Task['db:migrate'].invoke
    
    # Lancer le seed avancé
    Rake::Task['seed:advanced'].invoke
  end
end

# Tâches pour tests et développement
namespace :seed do
  namespace :test do
    desc "Teste le téléchargement d'un fichier exemple"
    task download_test: :environment do
      puts "\n🧪 Test de téléchargement d'un fichier..."
      
      downloader = SampleFilesDownloader.new
      test_url = 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf'
      
      begin
        file_path = downloader.send(:download_from_url, test_url, 'test.pdf')
        if File.exist?(file_path)
          puts "✅ Fichier téléchargé avec succès: #{file_path}"
          puts "   Taille: #{File.size(file_path)} octets"
        else
          puts "❌ Échec du téléchargement"
        end
      rescue => e
        puts "❌ Erreur: #{e.message}"
      end
    end
    
    desc "Teste la génération de données réalistes"
    task data_generator: :environment do
      puts "\n🧪 Test du générateur de données réalistes..."
      
      puts "\n👤 Utilisateur généré:"
      user = RealisticDataGenerator.generate_user
      user.each { |k, v| puts "  #{k}: #{v}" }
      
      puts "\n🏗️ Projet généré:"
      project = RealisticDataGenerator.generate_project
      project.each { |k, v| puts "  #{k}: #{v}" }
      
      puts "\n📄 Nom de document généré:"
      [:pdf, :images, :office].each do |cat|
        puts "  #{cat}: #{RealisticDataGenerator.generate_document_name(cat)}"
      end
      
      puts "\n🏷️ Tags générés:"
      puts "  #{RealisticDataGenerator.generate_tags.join(', ')}"
    end
  end
end