#!/usr/bin/env ruby

# Script de test rapide pour vérifier l'accès du contrôleur

# Connexion à la base de données Rails
require_relative 'config/environment'

puts "🔍 Test d'accès pour l'utilisateur contrôleur..."

# Trouver l'utilisateur contrôleur
controller_user = User.find_by(email: "controle@promotex.fr")
if controller_user.nil?
  puts "❌ Utilisateur contrôleur non trouvé"
  exit 1
end

puts "✅ Utilisateur trouvé: #{controller_user.email}"
puts "   - Rôle: #{controller_user.role}"
puts "   - Organisation: #{controller_user.organization.name}"
puts "   - Permissions: #{controller_user.permissions}"

# Trouver un projet de test
project = Immo::Promo::Project.first
if project.nil?
  puts "❌ Aucun projet trouvé"
  exit 1
end

puts "✅ Projet de test: #{project.name}"
puts "   - Organisation: #{project.organization.name}"
puts "   - Manager: #{project.project_manager&.email || 'Aucun'}"

# Tester la policy directement
policy = Immo::Promo::ProjectPolicy.new(controller_user, project)

puts "\n🔍 Tests des permissions:"
puts "   - index?: #{policy.index?}"
puts "   - show?: #{policy.show?}"
puts "   - create?: #{policy.create?}"
puts "   - update?: #{policy.update?}"

# Tester le scope
scope = Immo::Promo::ProjectPolicy::Scope.new(controller_user, Immo::Promo::Project).resolve
puts "\n🔍 Scope de la policy:"
puts "   - Projets visibles: #{scope.count}"
puts "   - Projets: #{scope.pluck(:name).join(', ')}"

# Vérifier si l'utilisateur peut accéder au projet via les méthodes helper du modèle User
if controller_user.respond_to?(:user_is_admin?)
  puts "\n🔍 Méthodes helper User:"
  puts "   - user_is_admin?: #{controller_user.user_is_admin?}"
  puts "   - admin?: #{controller_user.admin?}" if controller_user.respond_to?(:admin?)
  puts "   - super_admin?: #{controller_user.super_admin?}" if controller_user.respond_to?(:super_admin?)
end

if controller_user.respond_to?(:has_permission?)
  puts "   - has_permission?('immo_promo:access'): #{controller_user.has_permission?('immo_promo:access')}"
  puts "   - has_permission?('immo_promo:read'): #{controller_user.has_permission?('immo_promo:read')}"
end

# Vérifier l'organisation
if controller_user.organization == project.organization
  puts "\n✅ Même organisation - OK"
else
  puts "\n❌ Organisations différentes:"
  puts "   - Utilisateur: #{controller_user.organization.name}"
  puts "   - Projet: #{project.organization.name}"
end

puts "\n🎯 Conclusion:"
if policy.show?
  puts "✅ L'utilisateur DEVRAIT pouvoir accéder au projet selon la policy"
  puts "   → Le problème est probablement dans le contrôleur ou la vue"
else
  puts "❌ L'utilisateur ne peut PAS accéder au projet selon la policy"
  puts "   → Le problème est dans la policy elle-même"
end