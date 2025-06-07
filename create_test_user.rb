#!/usr/bin/env ruby

puts "Creating test user..."

begin
  org = Organization.first || Organization.create!(name: 'Test Organization')
  puts "✓ Organization: #{org.name}"
  
  user = User.find_by(email: 'test@example.com')
  if user
    puts "User already exists"
  else
    user = User.create!(
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123',
      first_name: 'Test',
      last_name: 'User',
      organization: org
    )
    puts "User created"
  end
  
  puts "✓ User created/found: #{user.email}"
  puts "✓ Organization: #{user.organization.name}"
  puts "\nYou can now login with:"
  puts "Email: test@example.com"
  puts "Password: password123"
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(5)
end