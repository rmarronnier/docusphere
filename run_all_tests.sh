#!/bin/bash

echo "🧪 Running all tests..."
echo "======================="

# Run GED specs
echo -e "\n📁 GED Controller Specs:"
docker compose exec -e RAILS_ENV=test web bundle exec rspec spec/controllers/ged_controller_spec.rb --format progress

# Run Immo::Promo specs
echo -e "\n🏢 Immo::Promo Specs:"
docker compose exec -e RAILS_ENV=test web bundle exec rspec spec/models/immo/promo/ spec/controllers/immo/promo/ spec/policies/immo/promo/ --format progress

# Run all specs with summary
echo -e "\n📊 Full Test Suite:"
docker compose exec -e RAILS_ENV=test web bundle exec rspec --format documentation | grep -E "(examples?|failures?|pending)"

echo -e "\n✅ Test run complete!"