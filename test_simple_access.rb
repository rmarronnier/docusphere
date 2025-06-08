#!/usr/bin/env ruby

# Test simple d'accès sans système complet

require_relative 'config/environment'
require 'net/http'
require 'uri'

puts "🌐 Test d'accès HTTP direct..."

# Démarrer un serveur de test
require 'rack/test'

class TestApp
  include Rack::Test::Methods

  def app
    Rails.application
  end

  def test_access
    # Simuler une session utilisateur
    controller_user = User.find_by(email: "controle@promotex.fr")
    project = Immo::Promo::Project.first
    
    puts "👤 Utilisateur de test: #{controller_user.email}"
    puts "📋 Projet de test: #{project.name} (ID: #{project.id})"
    
    # Créer une session
    post '/users/sign_in', {
      'user[email]' => controller_user.email,
      'user[password]' => 'password123' # mot de passe des seeds
    }
    
    puts "📋 Statut de connexion: #{last_response.status}"
    
    if last_response.status == 302
      puts "✅ Connexion réussie"
      
      # Tester l'accès à la liste des projets
      get '/immo/promo/projects'
      puts "📋 Accès liste projets: #{last_response.status}"
      
      if last_response.status == 200
        puts "✅ Liste des projets accessible"
        
        # Tester l'accès aux détails du projet
        get "/immo/promo/projects/#{project.id}"
        puts "📋 Accès détails projet: #{last_response.status}"
        
        if last_response.status == 200
          puts "✅ Détails du projet accessibles"
          puts "📄 Contenu (premier 200 chars): #{last_response.body[0..200]}..."
        else
          puts "❌ Détails du projet inaccessibles"
          puts "📄 Réponse: #{last_response.body[0..500]}..."
        end
      else
        puts "❌ Liste des projets inaccessible"
        puts "📄 Réponse: #{last_response.body[0..500]}..."
      end
    else
      puts "❌ Échec de connexion"
      puts "📄 Réponse: #{last_response.body[0..500]}..."
    end
  end
end

begin
  test_app = TestApp.new
  test_app.test_access
rescue => e
  puts "❌ Erreur lors du test: #{e.message}"
  puts "📄 Backtrace: #{e.backtrace.first(3).join("\n")}"
end