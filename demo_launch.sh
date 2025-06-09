#!/bin/bash

echo "🚀 DocuSphere Demo Quick Launch"
echo "=============================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop."
    exit 1
fi

echo "✅ Docker is running"

# Stop any existing containers
echo "🛑 Stopping existing containers..."
docker-compose down

# Start fresh
echo "🚀 Starting services..."
docker-compose up -d

# Wait for services
echo "⏳ Waiting for services to be ready..."
sleep 10

# Setup demo data
echo "📊 Setting up demo data..."
docker-compose run --rm web rails demo:setup

# Health check
echo "🏥 Running health check..."
docker-compose run --rm web rails demo:health_check

echo ""
echo "✅ Demo environment is ready!"
echo ""
echo "🌐 Access the application at: http://localhost:3000"
echo "📧 Login: admin@docusphere.fr"
echo "🔑 Password: password123"
echo ""
echo "📋 Quick commands:"
echo "  - View logs: docker-compose logs -f web"
echo "  - Restart if needed: docker-compose restart web"
echo "  - Emergency reset: docker-compose run --rm web rails demo:reset"
echo ""
echo "Good luck with your demo! 🎉"