# Simple seed for testing navbar functionality
puts '🌱 Creating simple test data...'

# Clean only what exists safely
begin
  User.destroy_all
  Organization.destroy_all
rescue => e
  puts "Warning: #{e.message}"
end

# Create organization
org = Organization.create!(
  name: 'Test Organization',
  slug: 'test-organization'
)

# Create admin user
admin = User.create!(
  email: 'admin@test.com',
  password: 'password123',
  password_confirmation: 'password123',
  first_name: 'Admin',
  last_name: 'User',
  role: 'admin',
  organization: org
)

# Create regular user
user = User.create!(
  email: 'user@test.com',
  password: 'password123',
  password_confirmation: 'password123',
  first_name: 'Regular',
  last_name: 'User',
  role: 'user',
  organization: org
)

puts "✅ Created organization: #{org.name}"
puts "✅ Created admin user: #{admin.email}"
puts "✅ Created regular user: #{user.email}"
puts '🚀 Ready for testing!'
puts ""
puts "You can log in with:"
puts "  Admin: admin@test.com / password123"
puts "  User:  user@test.com / password123"