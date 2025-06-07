#!/usr/bin/env ruby

puts "Running Immo::Promo specs summary..."
puts "===================================="

# Run each type of spec separately and count
specs = {
  "Models" => "spec/models/immo/promo/",
  "Controllers" => "spec/controllers/immo/promo/",
  "Policies" => "spec/policies/immo/promo/"
}

total_examples = 0
total_failures = 0

specs.each do |type, path|
  puts "\n📦 #{type}:"
  output = `docker compose exec -e RAILS_ENV=test web bundle exec rspec #{path} --format json 2>/dev/null`
  
  begin
    result = JSON.parse(output)
    examples = result["summary"]["example_count"]
    failures = result["summary"]["failure_count"]
    total_examples += examples
    total_failures += failures
    
    puts "  Examples: #{examples}"
    puts "  Failures: #{failures}"
    puts "  Status: #{failures == 0 ? '✅ Passing' : '❌ Failing'}"
  rescue => e
    puts "  ⚠️  Could not parse results"
  end
end

puts "\n" + "="*40
puts "📊 TOTAL SUMMARY:"
puts "  Total Examples: #{total_examples}"
puts "  Total Failures: #{total_failures}"
puts "  Overall Status: #{total_failures == 0 ? '✅ All tests passing!' : "❌ #{total_failures} tests failing"}"
puts "="*40