#!/usr/bin/env ruby

require 'net/http'
require 'uri'

puts "Testing dashboard access with authentication..."

begin
  # Simuler une connexion utilisateur
  user = User.find_by(email: 'test@example.com')
  if user
    puts "✓ User found: #{user.email}"
    
    # Test avec ApplicationController simulé
    class TestController < ApplicationController
      attr_accessor :current_user
      
      def params
        ActionController::Parameters.new({})
      end
    end
    
    controller = TestController.new
    controller.current_user = user
    
    # Vérifier la policy
    policy = Immo::Promo::ProjectPolicy.new(user, Immo::Promo::Project)
    puts "✓ Dashboard policy check: #{policy.dashboard?}"
    
    # Vérifier l'accès aux projets
    projects = Pundit.policy_scope(user, Immo::Promo::Project)
    puts "✓ Projects accessible: #{projects.count}"
    
    puts "\n🎉 Dashboard should now be accessible!"
    puts "\nTo access:"
    puts "1. Login at http://localhost:3000/users/sign_in"
    puts "2. Use: test@example.com / password123"
    puts "3. Navigate to http://localhost:3000/immo/promo"
  else
    puts "! User not found. Please run the seed or create a test user."
  end
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(5)
end