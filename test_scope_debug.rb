#!/usr/bin/env ruby

puts "Testing scope debug..."

begin
  user = User.find_by(email: 'policy_test@example.com')
  puts "User: #{user.email}"
  puts "Organization: #{user.organization.name}"
  
  # All projects
  all_projects = Immo::Promo::Project.all
  puts "\nAll projects: #{all_projects.count}"
  all_projects.each do |p|
    puts "- #{p.name} (org: #{p.organization.name}, manager: #{p.project_manager&.email})"
  end
  
  # Projects in user's org
  org_projects = Immo::Promo::Project.where(organization: user.organization)
  puts "\nProjects in user's org: #{org_projects.count}"
  
  # Projects where user is manager
  managed_projects = Immo::Promo::Project.where(project_manager: user)
  puts "Projects managed by user: #{managed_projects.count}"
  
  # Test the scope directly
  policy = Immo::Promo::ProjectPolicy.new(user, Immo::Promo::Project)
  scope = Immo::Promo::ProjectPolicy::Scope.new(user, Immo::Promo::Project).resolve
  puts "\nPolicy scope result: #{scope.count}"
  puts "SQL: #{scope.to_sql}"
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(5)
end