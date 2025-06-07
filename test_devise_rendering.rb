#!/usr/bin/env ruby

puts "Testing Devise rendering..."

begin
  # Simuler une requête
  require 'action_dispatch/testing/test_request'
  
  controller = Devise::SessionsController.new
  request = ActionDispatch::TestRequest.create
  response = ActionDispatch::TestResponse.new
  
  controller.request = request
  controller.response = response
  
  # Configurer l'environnement
  request.env["devise.mapping"] = Devise.mappings[:user]
  
  # Essayer de rendre la vue
  puts "Attempting to render sign_in view..."
  controller.instance_variable_set(:@resource, User.new)
  controller.instance_variable_set(:@resource_name, :user)
  
  # Forcer le rendu
  controller.render_to_string(template: 'devise/sessions/new', layout: 'layouts/application')
  
  puts "✓ Rendering successful!"
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts "\nBacktrace:"
  puts e.backtrace.first(10)
end