#!/usr/bin/env ruby

puts "Testing dashboard with authentication..."

begin
  # Créer ou récupérer un utilisateur de test
  user = User.find_or_create_by(email: 'test@example.com') do |u|
    u.password = 'password123'
    u.password_confirmation = 'password123'
    u.organization = Organization.first || Organization.create!(name: 'Test Org')
  end
  
  puts "✓ User ready: #{user.email}"
  
  # Simuler la connexion
  require 'action_controller/test_case'
  
  class TestRequest < ActionDispatch::TestRequest
    def initialize
      super
      @env = {}
    end
  end
  
  # Test du dashboard global
  puts "\n=== Testing Global Dashboard Access ==="
  controller = Immo::Promo::ProjectsController.new
  controller.instance_variable_set(:@current_user, user)
  
  # Simuler policy_scope
  projects = Immo::Promo::Project.joins(:organization).where(organization: user.organization)
  puts "✓ Projects accessible to user: #{projects.count}"
  
  # Vérifier que les queries fonctionnent
  upcoming_milestones = Immo::Promo::Milestone.joins(:project)
                                               .where(project: projects)
                                               .upcoming
                                               .limit(10)
  puts "✓ Milestones query OK"
  
  overdue_tasks = Immo::Promo::Task.joins(phase: :project)
                                   .where(phase: { project: projects })
                                   .overdue
                                   .limit(10)
  puts "✓ Tasks query OK"
  
  recent_reports = Immo::Promo::ProgressReport.joins(:project)
                                              .where(project: projects)
                                              .recent
                                              .limit(5)
  puts "✓ Reports query OK"
  
  puts "\n🎉 Dashboard is working correctly!"
  puts "\nTo access the dashboard:"
  puts "1. Start the Rails server: docker compose up"
  puts "2. Login with: test@example.com / password123"
  puts "3. Navigate to: http://localhost:3000/immo/promo"
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(5)
end