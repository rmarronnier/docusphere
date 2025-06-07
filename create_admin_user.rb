#!/usr/bin/env ruby

puts "Creating admin user..."

begin
  # Trouver ou créer l'organisation Docusphere
  org = Organization.find_or_create_by!(name: 'Docusphere')
  puts "✓ Organization: #{org.name}"
  
  # Créer l'utilisateur admin
  user = User.find_or_initialize_by(email: 'admin@docusphere.fr')
  
  if user.new_record?
    user.password = 'password123'
    user.password_confirmation = 'password123'
    user.first_name = 'Admin'
    user.last_name = 'Docusphere'
    user.organization = org
    user.role = 'admin'
    user.save!
    puts "✓ Admin user created: #{user.email}"
  else
    puts "✓ Admin user already exists: #{user.email}"
  end
  
  puts "\nLogin credentials:"
  puts "Email: admin@docusphere.fr"
  puts "Password: password123"
  puts "Role: #{user.role}"
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(5)
end