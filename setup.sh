#!/bin/bash

echo "=== Configuration de Docusphere ==="

# Copier le fichier d'environnement
if [ ! -f .env ]; then
    cp .env.development .env
    echo "✓ Fichier .env créé"
fi

# Créer les fichiers lock vides s'ils n'existent pas
touch Gemfile.lock bun.lock

# Construire les images Docker
echo "Construction des images Docker..."
docker-compose build

# Démarrer les services de base de données
echo "Démarrage des services..."
docker-compose up -d db redis elasticsearch

# Attendre que PostgreSQL soit prêt
echo "Attente de PostgreSQL..."
sleep 15

# Copier les fichiers lock générés par Docker
echo "Récupération des fichiers de dépendances..."
docker-compose run --rm web sh -c "cp Gemfile.lock /tmp/ && cp bun.lock /tmp/" || true
docker cp $(docker-compose ps -q web):/tmp/Gemfile.lock . 2>/dev/null || true
docker cp $(docker-compose ps -q web):/tmp/bun.lock . 2>/dev/null || true

# Créer les répertoires nécessaires
echo "Création des répertoires..."
docker-compose run --rm web mkdir -p db/cache_migrate db/queue_migrate db/cable_migrate

# Créer les bases de données
echo "Création des bases de données..."
docker-compose run --rm web rails db:create

echo "=== Configuration terminée ==="
echo ""
echo "Pour démarrer l'application :"
echo "  docker-compose up"
echo ""
echo "L'application sera accessible sur http://localhost:3000"
echo ""
echo "Pour créer les tables et les données initiales :"
echo "  docker-compose run --rm web rails generate devise:install"
echo "  docker-compose run --rm web rails generate devise User"
echo "  docker-compose run --rm web rails db:migrate"
echo "  docker-compose run --rm web rails db:seed"