namespace :immo_promo do
  namespace :db do
    desc "Load the ImmoPromo engine seeds"
    task seed: :environment do
      seed_file = File.join(File.dirname(__FILE__), '..', '..', 'db', 'seeds.rb')
      load(seed_file) if File.exist?(seed_file)
    end

    desc "Reset ImmoPromo data and load seeds"
    task reseed: :environment do
      puts "🧹 Nettoyage des données ImmoPromo existantes..."
      
      # Supprimer dans l'ordre des dépendances
      Immo::Promo::Task.destroy_all
      Immo::Promo::BudgetLine.destroy_all
      Immo::Promo::Budget.destroy_all
      Immo::Promo::Contract.destroy_all
      Immo::Promo::Milestone.destroy_all
      Immo::Promo::PermitCondition.destroy_all
      Immo::Promo::Permit.destroy_all
      Immo::Promo::Certification.destroy_all
      Immo::Promo::Stakeholder.destroy_all
      Immo::Promo::Phase.destroy_all
      Immo::Promo::Project.destroy_all
      
      # Supprimer les utilisateurs de test (optionnel)
      test_emails = [
        "directeur@promotex.fr",
        "chef.projet@promotex.fr", 
        "architecte@promotex.fr",
        "commercial@promotex.fr",
        "controle@promotex.fr"
      ]
      User.where(email: test_emails).destroy_all
      
      # Supprimer l'organisation de test
      Organization.find_by(name: "Promotex Immobilier")&.destroy
      
      puts "✅ Nettoyage terminé"
      puts ""
      
      # Charger les nouvelles seeds
      Rake::Task['immo_promo:db:seed'].invoke
    end
  end

  desc "Setup ImmoPromo demo environment"
  task setup_demo: :environment do
    puts "🎬 Configuration de l'environnement de démonstration ImmoPromo..."
    
    Rake::Task['immo_promo:db:reseed'].invoke
    
    puts ""
    puts "🎉 Environnement de démonstration prêt !"
    puts ""
    puts "🌐 Pour tester les différents profils, connectez-vous avec:"
    puts "   • Directeur: directeur@promotex.fr / test123"
    puts "   • Chef de projet: chef.projet@promotex.fr / test123"
    puts "   • Architecte: architecte@promotex.fr / test123"
    puts "   • Commercial: commercial@promotex.fr / test123"
    puts "   • Contrôleur: controle@promotex.fr / test123"
    puts ""
    puts "📍 URL du module: /immo/promo/projects"
  end
end