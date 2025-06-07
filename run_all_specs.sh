#!/bin/bash

echo "Running all Immo::Promo specs..."
echo "================================"

# Run model specs
echo -e "\n📦 Running Model Specs..."
docker compose exec -e RAILS_ENV=test web bundle exec rspec spec/models/immo/promo/ --format progress

# Run controller specs  
echo -e "\n🎮 Running Controller Specs..."
docker compose exec -e RAILS_ENV=test web bundle exec rspec spec/controllers/immo/promo/ --format progress

# Run policy specs
echo -e "\n🔒 Running Policy Specs..."
docker compose exec -e RAILS_ENV=test web bundle exec rspec spec/policies/immo/promo/ --format progress

# Run all together with summary
echo -e "\n📊 Running All Specs Together..."
docker compose exec -e RAILS_ENV=test web bundle exec rspec spec/models/immo/promo/ spec/controllers/immo/promo/ spec/policies/immo/promo/ --format documentation --format json --out rspec_results.json

echo -e "\n✅ Test suite complete!"