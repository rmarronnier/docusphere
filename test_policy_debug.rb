#!/usr/bin/env ruby

puts "Testing policy setup..."

begin
  # Create test data
  org = Organization.first || Organization.create!(name: 'Test Org')
  user = User.find_or_create_by(email: 'policy_test@example.com') do |u|
    u.password = 'password123'
    u.first_name = 'Policy'
    u.last_name = 'Test'
    u.organization = org
  end
  
  project = Immo::Promo::Project.find_or_create_by!(reference: 'TEST-001', organization: org) do |p|
    p.name = 'Test Project'
    p.project_type = 'residential'
    p.status = 'planning'
    p.project_manager = user
    p.start_date = Date.today
    p.end_date = Date.today + 1.year
  end
  
  puts "✓ Test data created"
  
  # Test policy
  policy = Immo::Promo::ProjectPolicy.new(user, project)
  puts "\nTesting ProjectPolicy methods:"
  puts "- index?: #{policy.index?}"
  puts "- dashboard?: #{policy.dashboard?}"
  puts "- show?: #{policy.show?}"
  puts "- create?: #{policy.create?}"
  puts "- update?: #{policy.update?}"
  puts "- destroy?: #{policy.destroy?}"
  
  # Test scope
  puts "\nTesting scope:"
  scope = Immo::Promo::ProjectPolicy::Scope.new(user, Immo::Promo::Project).resolve
  puts "- Projects in scope: #{scope.count}"
  
  # Test with Pundit
  puts "\nTesting with Pundit:"
  puts "- Pundit.policy(user, project).show?: #{Pundit.policy(user, project).show?}"
  puts "- Pundit.policy_scope(user, Immo::Promo::Project).count: #{Pundit.policy_scope(user, Immo::Promo::Project).count}"
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(5)
end