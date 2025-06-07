#!/usr/bin/env ruby

require 'net/http'
require 'uri'

puts "Testing login page access..."

begin
  uri = URI.parse("http://localhost:3000/users/sign_in")
  response = Net::HTTP.get_response(uri)
  
  puts "Response code: #{response.code}"
  puts "Response message: #{response.message}"
  
  if response.code == "200"
    puts "✓ Login page is accessible!"
    if response.body.include?("Log in")
      puts "✓ Login form is present"
    end
  elsif response.code == "302"
    puts "! Redirected to: #{response['location']}"
  else
    puts "✗ Unexpected response code: #{response.code}"
  end
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts "Make sure the Rails server is running with: docker compose up"
end