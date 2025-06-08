#!/usr/bin/env ruby

require_relative 'config/environment'

puts "🔍 Test du scope pour l'utilisateur contrôleur..."

controller_user = User.find_by(email: "controle@promotex.fr")
puts "✅ Utilisateur: #{controller_user.email}"

# Test du scope directement
scope = Immo::Promo::ProjectPolicy::Scope.new(controller_user, Immo::Promo::Project)
projects = scope.resolve
puts "📊 Projets dans le scope: #{projects.count}"
projects.each do |project|
  puts "   - #{project.name} (ID: #{project.id})"
end

if projects.any?
  first_project = projects.first
  puts "\n🎯 Test d'accès au premier projet: #{first_project.name}"
  
  # Simuler ce que fait le contrôleur
  begin
    found_project = scope.resolve.find(first_project.id)
    puts "✅ Projet trouvé via scope.find: #{found_project.name}"
  rescue ActiveRecord::RecordNotFound => e
    puts "❌ Projet NON trouvé via scope.find: #{e.message}"
  end
  
  # Tester la policy show
  policy = Immo::Promo::ProjectPolicy.new(controller_user, first_project)
  puts "🔐 Policy show?: #{policy.show?}"
  
  # Tester si Pundit.policy_scope fonctionne
  begin
    pundit_scope = Pundit.policy_scope(controller_user, Immo::Promo::Project)
    puts "📋 Pundit policy_scope compte: #{pundit_scope.count}"
    found_via_pundit = pundit_scope.find(first_project.id)
    puts "✅ Trouvé via Pundit policy_scope: #{found_via_pundit.name}"
  rescue => e
    puts "❌ Erreur avec Pundit policy_scope: #{e.message}"
  end
else
  puts "❌ Aucun projet dans le scope!"
end