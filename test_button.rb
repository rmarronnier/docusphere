#!/usr/bin/env ruby

# Test simple du composant Button

require_relative 'config/environment'

puts "Testing Button Component..."

begin
  # Test simple
  component = Ui::ButtonComponent.new(text: "Test")
  puts "✅ Basic button creation: OK"
  
  # Test avec variant
  component = Ui::ButtonComponent.new(text: "Test", variant: :primary)
  puts "✅ Button with variant: OK"
  
  # Test avec size
  component = Ui::ButtonComponent.new(text: "Test", size: :md)
  puts "✅ Button with size: OK"
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(5)
end