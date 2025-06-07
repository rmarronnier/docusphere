#!/usr/bin/env ruby

puts "=== Test simple des modèles ==="

# Test de base
puts "Tables disponibles:"
puts ActiveRecord::Base.connection.tables.select { |t| t.start_with?('immo_promo') }.join(', ')

# Test de création simple
puts "\nTest de création d'un projet..."

begin
  org = Organization.first || Organization.create!(name: 'Test Org', slug: 'test')
  puts "Organisation OK: #{org.name}"
  
  project = Immo::Promo::Project.new(
    name: 'Test Project',
    reference: 'TEST001',
    project_type: 'residential',
    organization: org
  )
  
  if project.valid?
    project.save!
    puts "Projet créé avec succès: #{project.name}"
  else
    puts "Erreurs de validation: #{project.errors.full_messages.join(', ')}"
  end
  
rescue => e
  puts "Erreur: #{e.message}"
end

puts "=== Fin du test ==="