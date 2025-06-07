#!/usr/bin/env ruby

require 'net/http'
require 'uri'

puts "Testing full login flow..."

begin
  # Test que la page de login est accessible
  uri = URI.parse("http://localhost:3000/users/sign_in")
  response = Net::HTTP.get_response(uri)
  
  if response.code == "200"
    puts "✓ Login page accessible"
  else
    puts "✗ Login page returned: #{response.code}"
  end
  
  # Test que l'accès à /immo/promo redirige vers login
  uri = URI.parse("http://localhost:3000/immo/promo")
  response = Net::HTTP.get_response(uri)
  
  if response.code == "302"
    puts "✓ Dashboard redirects to login (as expected)"
    puts "  Redirect to: #{response['location']}"
  else
    puts "✗ Dashboard returned: #{response.code}"
  end
  
  puts "\n📋 Summary:"
  puts "1. Login page is working at: http://localhost:3000/users/sign_in"
  puts "2. Use credentials: test@example.com / password123"
  puts "3. After login, go to: http://localhost:3000/immo/promo"
  
rescue => e
  puts "❌ Error: #{e.message}"
end