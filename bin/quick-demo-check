# Quick check script for demo readiness
puts "🔍 Quick Demo Check"
puts "=" * 40

# Check database connection
begin
  puts "📊 Database check..."
  User.connection.execute("SELECT 1")
  user_count = User.count
  puts "✅ Database OK (#{user_count} users)"
rescue => e
  puts "❌ Database error: #{e.message}"
  exit 1
end

# Check admin user
begin
  admin = User.find_by(email: "admin@docusphere.fr")
  if admin
    puts "✅ Admin user exists"
  else
    puts "⚠️  Creating admin user..."
    org = Organization.first || Organization.create!(name: "DocuSphere Demo")
    User.create!(
      email: "admin@docusphere.fr",
      password: "password123",
      first_name: "Admin",
      last_name: "Demo",
      organization: org,
      role: "admin",
      confirmed_at: Time.current
    )
    puts "✅ Admin user created"
  end
rescue => e
  puts "❌ Admin user error: #{e.message}"
end

# Check spaces
begin
  space_count = Space.count
  puts "✅ Spaces: #{space_count}"
  
  if space_count == 0
    puts "⚠️  Creating demo space..."
    org = Organization.first
    Space.create!(
      name: "Espace Demo",
      description: "Espace de démonstration",
      organization: org,
      space_type: "project"
    )
    puts "✅ Demo space created"
  end
rescue => e
  puts "❌ Space error: #{e.message}"
end

# Check ImmoPromo
begin
  if defined?(Immo::Promo::Project)
    project_count = Immo::Promo::Project.count
    puts "✅ ImmoPromo Projects: #{project_count}"
    
    if project_count == 0
      puts "⚠️  Creating demo project..."
      org = Organization.first
      manager = User.find_by(role: ["admin", "manager"])
      
      project = Immo::Promo::Project.create!(
        name: "Résidence Les Jardins",
        organization: org,
        project_type: "residential",
        status: "in_progress",
        description: "Projet résidentiel de démonstration",
        address: "123 Avenue des Fleurs",
        city: "Paris",
        postal_code: "75001",
        total_units: 48,
        project_manager: manager
      )
      puts "✅ Demo project created"
    end
  else
    puts "❌ ImmoPromo module not loaded"
  end
rescue => e
  puts "❌ ImmoPromo error: #{e.message}"
end

# Check documents
begin
  doc_count = Document.count
  puts "✅ Documents: #{doc_count}"
rescue => e
  puts "❌ Document error: #{e.message}"
end

# Check sample files
sample_path = Rails.root.join("storage/sample_documents")
if Dir.exist?(sample_path)
  file_count = Dir.glob(File.join(sample_path, "*")).count
  puts "✅ Sample files: #{file_count}"
else
  puts "❌ Sample documents directory missing"
end

puts "\n" + "=" * 40
puts "📋 Summary:"
puts "  - Login: admin@docusphere.fr / password123"
puts "  - URL: http://localhost:3000"
puts "  - GED: http://localhost:3000/ged"
puts "  - ImmoPromo: http://localhost:3000/immo/promo"
puts "=" * 40