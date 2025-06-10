#!/usr/bin/env ruby

# Quick test to check if Lookbook URLs are accessible
require 'net/http'
require 'uri'

BASE_URL = "http://localhost:3000"

urls_to_test = [
  "/rails/lookbook",
  "/rails/lookbook/preview/ui/button/default",
  "/rails/lookbook/preview/ui/status_badge/default",
  "/rails/lookbook/preview/ui/status-badge/default"  # Test with hyphen
]

puts "Testing Lookbook URLs..."

urls_to_test.each do |path|
  begin
    uri = URI("#{BASE_URL}#{path}")
    response = Net::HTTP.get_response(uri)
    puts "#{path}: #{response.code} #{response.message}"
  rescue => e
    puts "#{path}: ERROR - #{e.message}"
  end
end