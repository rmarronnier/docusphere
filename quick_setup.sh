#!/bin/bash

echo "=== Configuration rapide des modèles ==="

# Supprimer les migrations existantes
docker-compose run --rm web rm -f db/migrate/*

# Créer les migrations dans le bon ordre
echo "Création des migrations..."

# Organization (doit être créé en premier)
docker-compose run --rm web rails generate migration CreateOrganizations \
  name:string \
  slug:string:uniq \
  description:text

# Users (avec référence à organization)
docker-compose run --rm web rails generate migration CreateUsers \
  first_name:string \
  last_name:string \
  role:string \
  organization:references

# Ajouter Devise aux Users
docker-compose run --rm web rails generate devise User

# Spaces
docker-compose run --rm web rails generate migration CreateSpaces \
  name:string \
  slug:string \
  description:text \
  organization:references

# Folders (avec ancestry pour l'arborescence)
docker-compose run --rm web rails generate migration CreateFolders \
  name:string \
  description:text \
  space:references \
  ancestry:string:index

# Documents (modèle principal)
docker-compose run --rm web rails generate migration CreateDocuments \
  title:string \
  description:text \
  content:text \
  extracted_content:text \
  status:string \
  user:references \
  space:references \
  folder:references \
  retention_date:date \
  destruction_date:date

# Tags
docker-compose run --rm web rails generate migration CreateTags \
  name:string:uniq

# DocumentTags (table de liaison)
docker-compose run --rm web rails generate migration CreateDocumentTags \
  document:references \
  tag:references

# DocumentVersions
docker-compose run --rm web rails generate migration CreateDocumentVersions \
  document:references \
  version_number:integer \
  comment:text \
  created_by:references

# Exécuter les migrations
echo "Exécution des migrations..."
docker-compose run --rm web rails db:migrate

# Active Storage
echo "Installation d'Active Storage..."
docker-compose run --rm web rails active_storage:install
docker-compose run --rm web rails db:migrate

# Seeds
echo "Création des données de test..."
docker-compose run --rm web rails db:seed

echo "=== Configuration terminée ! ==="