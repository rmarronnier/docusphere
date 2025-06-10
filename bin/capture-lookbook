#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'

# URLs des composants à capturer
urls = [
  ["http://localhost:3000/rails/lookbook", "00_lookbook_home"],
  ["http://localhost:3000/rails/lookbook/preview/ui/data_grid_component_preview/default", "01_data_grid_default"],
  ["http://localhost:3000/rails/lookbook/preview/ui/data_grid_component_preview/with_inline_actions", "02_data_grid_inline_actions"],
  ["http://localhost:3000/rails/lookbook/preview/ui/data_grid_component_preview/with_dropdown_actions", "03_data_grid_dropdown_actions"],
  ["http://localhost:3000/rails/lookbook/preview/ui/data_grid_component_preview/with_formatting", "04_data_grid_formatting"],
  ["http://localhost:3000/rails/lookbook/preview/ui/data_grid_component_preview/empty_default", "05_data_grid_empty"],
  ["http://localhost:3000/rails/lookbook/preview/ui/button_component_preview/variants", "06_button_variants"],
  ["http://localhost:3000/rails/lookbook/preview/ui/button_component_preview/sizes", "07_button_sizes"],
  ["http://localhost:3000/rails/lookback/preview/ui/card_component_preview/default", "08_card_default"],
  ["http://localhost:3000/rails/lookbook/preview/ui/alert_component_preview/types", "09_alert_types"],
  ["http://localhost:3000/rails/lookbook/preview/ui/modal_component_preview/default", "10_modal_default"]
]

puts "📸 Lookbook Screenshot URLs"
puts "=" * 50
puts ""
puts "Ouvrez votre navigateur et visitez ces URLs pour voir les composants :"
puts ""

urls.each_with_index do |(url, name), index|
  puts "#{index + 1}. #{name}:"
  puts "   #{url}"
  puts ""
end

puts "=" * 50
puts ""
puts "Pour capturer un screenshot sur Mac :"
puts "1. Ouvrez l'URL dans votre navigateur"
puts "2. Appuyez sur Cmd+Shift+4 puis Espace"
puts "3. Cliquez sur la fenêtre du navigateur"
puts "4. Sauvegardez dans : tmp/screenshots/lookbook_manual/"
puts ""
puts "Ou utilisez l'extension de navigateur pour capturer la page complète."