# Essential seeds - minimal data for demo
puts "Seeding essential data only..."

# Just create the default organization and admin user
org = Organization.find_or_create_by!(name: "DocuSphere") do |o|
  o.description = "Organisation principale"
  o.org_type = "enterprise"
end

admin = User.find_or_create_by!(email: "admin@docusphere.fr") do |u|
  u.password = "password123"
  u.first_name = "Admin"
  u.last_name = "DocuSphere"
  u.organization = org
  u.role = "admin"
  u.confirmed_at = Time.current
end

puts "✅ Essential data seeded!"