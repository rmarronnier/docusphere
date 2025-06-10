#!/usr/bin/env ruby

# Trouver tous les fichiers app
app_files = Dir.glob("app/**/*.rb").select do |f|
  f =~ /\/(models|controllers|services|components|jobs|helpers|policies)\//
end

# Trouver tous les fichiers spec
spec_files = Dir.glob("spec/**/*_spec.rb")

# Créer un mapping des fichiers spec
spec_map = {}
spec_files.each do |spec_file|
  # Extraire le nom du fichier testé depuis le nom du spec
  if spec_file =~ /spec\/(.+)_spec\.rb$/
    tested_file = $1
    spec_map[tested_file] = spec_file
  end
end

# Identifier les fichiers sans tests
missing_tests = []

app_files.each do |app_file|
  # Extraire le chemin relatif depuis app/
  if app_file =~ /app\/(.+)\.rb$/
    relative_path = $1
    unless spec_map.has_key?(relative_path)
      missing_tests << app_file
    end
  end
end

puts "=== Fichiers sans tests (#{missing_tests.size}) ==="
missing_tests.sort.each do |file|
  puts file
end

# Grouper par type
by_type = missing_tests.group_by do |file|
  case file
  when /\/models\// then 'Models'
  when /\/controllers\// then 'Controllers'
  when /\/services\// then 'Services'
  when /\/components\// then 'Components'
  when /\/jobs\// then 'Jobs'
  when /\/helpers\// then 'Helpers'
  when /\/policies\// then 'Policies'
  else 'Other'
  end
end

puts "\n=== Résumé par type ==="
by_type.each do |type, files|
  puts "#{type}: #{files.size}"
  files.each { |f| puts "  - #{f}" }
end