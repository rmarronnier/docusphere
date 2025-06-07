#!/usr/bin/env ruby

puts "Creating test project and user..."

org = Organization.first || Organization.create!(name: 'Test Org', slug: 'test')
puts "Organization: #{org.name}"

user = User.find_by(email: 'admin@test.com') || User.create!(
  first_name: 'Admin',
  last_name: 'Test',
  email: 'admin@test.com',
  password: 'password123',
  organization: org,
  role: 'admin'
)

user.add_permission('immo_promo:read')
user.add_permission('immo_promo:write')
puts "User: #{user.full_name} with permissions added"

project = Immo::Promo::Project.create!(
  name: 'Test Dashboard Project',
  reference: 'TDP-001',
  project_type: 'residential',
  status: 'planning',
  organization: org,
  project_manager: user,
  start_date: Date.current,
  end_date: Date.current + 2.years,
  total_budget_cents: 500_000_000
)

puts "Project created with ID: #{project.id}"
puts "Access at: /immo/promo/projects/#{project.id}/dashboard"
puts "Test project creation completed successfully!"