#!/usr/bin/env ruby

puts "Testing dashboard access..."

begin
  # Simuler l'accès au dashboard
  controller = Immo::Promo::ProjectsController.new
  
  # Tester les queries du dashboard une par une
  projects = Immo::Promo::Project.active
  puts "✓ Projects query OK (#{projects.count} projects)"
  
  # Test milestones upcoming
  upcoming_milestones = Immo::Promo::Milestone.joins(:project)
                                             .where(project: projects)
                                             .upcoming
                                             .limit(10)
  puts "✓ Upcoming milestones query OK (#{upcoming_milestones.count} milestones)"
  
  # Test overdue tasks (c'est là que l'erreur se produisait)
  overdue_tasks = Immo::Promo::Task.joins(phase: :project)
                                   .where(phase: { project: projects })
                                   .overdue
                                   .limit(10)
  puts "✓ Overdue tasks query OK (#{overdue_tasks.count} tasks)"
  
  # Test recent reports
  recent_reports = Immo::Promo::ProgressReport.joins(:project)
                                              .where(project: projects)
                                              .recent
                                              .limit(5)
  puts "✓ Recent reports query OK (#{recent_reports.count} reports)"
  
  puts "\n🎉 All dashboard queries are working!"
  puts "The dashboard should now be accessible at /immo/promo/projects/:id/dashboard"
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(3)
end