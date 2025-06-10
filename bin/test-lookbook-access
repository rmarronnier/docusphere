#!/usr/bin/env ruby

# Script pour tester l'accès à Lookbook et lister les previews disponibles

require 'net/http'
require 'uri'

def test_url(url)
  uri = URI(url)
  response = Net::HTTP.get_response(uri)
  
  puts "\n📍 Testing: #{url}"
  puts "   Status: #{response.code} #{response.message}"
  
  if response.code == "302"
    puts "   Redirect to: #{response['location']}"
  elsif response.code == "200"
    # Extraire le titre de la page
    if response.body =~ /<title>(.*?)<\/title>/
      puts "   Title: #{$1}"
    end
    
    # Chercher des erreurs
    if response.body.include?("Error") || response.body.include?("error")
      puts "   ⚠️  Contains error messages"
    end
    
    # Chercher des liens de preview
    preview_links = response.body.scan(/href="([^"]*preview[^"]*)"/).flatten.uniq
    if preview_links.any?
      puts "   Found preview links:"
      preview_links.first(5).each do |link|
        puts "     - #{link}"
      end
    end
  end
rescue => e
  puts "   ❌ Error: #{e.message}"
end

# URLs à tester
base_url = ENV['DOCKER_CONTAINER'] ? "http://web:3000" : "http://localhost:3000"
urls = [
  "#{base_url}/rails/lookbook",
  "#{base_url}/rails/lookbook/preview/ui/button_component/default",
  "#{base_url}/rails/lookbook/preview/ui/data_grid_component/default"
]

puts "🔍 Testing Lookbook access..."

urls.each do |url|
  test_url(url)
end

puts "\n✅ Test complete"