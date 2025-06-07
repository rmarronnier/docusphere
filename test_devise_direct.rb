#!/usr/bin/env ruby

require 'rack/test'

class DeviseTest
  include Rack::Test::Methods
  
  def app
    Rails.application
  end
  
  def test_sign_in_page
    puts "Testing /users/sign_in..."
    header 'Host', 'localhost'
    get '/users/sign_in'
    
    puts "Status: #{last_response.status}"
    puts "Content-Type: #{last_response.content_type}"
    puts "Body length: #{last_response.body.length}"
    
    if last_response.status == 404
      puts "\n404 Error!"
      puts "Body preview:"
      puts last_response.body[0..500]
    elsif last_response.status == 200
      puts "\n✓ Success!"
      if last_response.body.include?("Connexion")
        puts "✓ Login form is present"
      end
    else
      puts "\nUnexpected status: #{last_response.status}"
    end
  end
end

begin
  tester = DeviseTest.new
  tester.test_sign_in_page
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(5)
end