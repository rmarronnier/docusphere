#!/bin/bash

echo "=== Finalisation de l'installation de Docusphere ==="

# Attendre que les services soient prêts
echo "Vérification des services..."
docker-compose up -d db redis elasticsearch
sleep 10

# Installer Devise
echo "Installation de Devise..."
docker-compose run --rm web rails generate devise:install

# Configurer Devise pour le français
echo "Configuration de Devise en français..."
docker-compose run --rm web sh -c "cat >> config/initializers/devise.rb << 'EOF'

  # Configuration pour l'interface en français
  config.default_locale = :fr
EOF"

# Générer le modèle User avec Devise
echo "Génération du modèle User avec Devise..."
docker-compose run --rm web rails generate devise User

# Ajouter les champs supplémentaires à User
echo "Ajout des champs supplémentaires à User..."
docker-compose run --rm web rails generate migration AddFieldsToUsers \
  first_name:string \
  last_name:string \
  organization:references \
  role:string

# Créer les migrations pour tous les modèles
echo "Création des migrations pour les modèles..."

# Organization
docker-compose run --rm web rails generate model Organization \
  name:string \
  slug:string:uniq \
  --skip

# Space
docker-compose run --rm web rails generate model Space \
  name:string \
  description:text \
  slug:string \
  organization:references \
  --skip

# Document
docker-compose run --rm web rails generate model Document \
  title:string \
  description:text \
  content:text \
  extracted_content:text \
  status:string \
  user:references \
  space:references \
  folder:references \
  parent:references \
  retention_date:date \
  destruction_date:date \
  --skip

# Folder
docker-compose run --rm web rails generate model Folder \
  name:string \
  description:text \
  space:references \
  parent:references \
  ancestry:string:index \
  --skip

# Workflow
docker-compose run --rm web rails generate model Workflow \
  name:string \
  description:text \
  status:string \
  space:references \
  user:references \
  workflow_template:references \
  --skip

# WorkflowStep
docker-compose run --rm web rails generate model WorkflowStep \
  name:string \
  description:text \
  position:integer \
  status:string \
  workflow:references \
  assignee:references \
  completed_by:references \
  completed_at:datetime \
  due_date:datetime \
  --skip

# Basket
docker-compose run --rm web rails generate model Basket \
  name:string \
  description:text \
  basket_type:string \
  user:references \
  space:references \
  --skip

# BasketItem
docker-compose run --rm web rails generate model BasketItem \
  basket:references \
  document:references \
  --skip

# MetadataTemplate
docker-compose run --rm web rails generate model MetadataTemplate \
  name:string \
  description:text \
  organization:references \
  --skip

# MetadataField
docker-compose run --rm web rails generate model MetadataField \
  name:string \
  field_key:string \
  field_type:string \
  options:text \
  required:boolean \
  position:integer \
  metadata_template:references \
  --skip

# DocumentMetadata
docker-compose run --rm web rails generate model DocumentMetadata \
  document:references \
  metadata_field:references \
  value:text \
  --skip

# Tag
docker-compose run --rm web rails generate model Tag \
  name:string:uniq \
  --skip

# DocumentTag
docker-compose run --rm web rails generate model DocumentTag \
  document:references \
  tag:references \
  --skip

# Group
docker-compose run --rm web rails generate model Group \
  name:string \
  description:text \
  organization:references \
  --skip

# UserGroup
docker-compose run --rm web rails generate model UserGroup \
  user:references \
  group:references \
  --skip


# DocumentVersion
docker-compose run --rm web rails generate model DocumentVersion \
  document:references \
  version_number:integer \
  comment:text \
  created_by:references \
  --skip

# DocumentLink
docker-compose run --rm web rails generate model DocumentLink \
  document:references \
  linked_document:references \
  link_type:string \
  --skip

# WorkflowDocument
docker-compose run --rm web rails generate model WorkflowDocument \
  workflow:references \
  document:references \
  --skip

# WorkflowTemplate
docker-compose run --rm web rails generate model WorkflowTemplate \
  name:string \
  description:text \
  organization:references \
  --skip

# SpaceUser
docker-compose run --rm web rails generate model SpaceUser \
  space:references \
  user:references \
  role:string \
  --skip

# SpaceMetadataTemplate
docker-compose run --rm web rails generate model SpaceMetadataTemplate \
  space:references \
  metadata_template:references \
  --skip

# FolderMetadata
docker-compose run --rm web rails generate model FolderMetadata \
  folder:references \
  metadata_field:references \
  value:text \
  --skip

# Notification
docker-compose run --rm web rails generate model Notification \
  user:references \
  title:string \
  message:text \
  read:boolean \
  link:string \
  --skip

# SearchQuery
docker-compose run --rm web rails generate model SearchQuery \
  user:references \
  name:string \
  query:text \
  filters:text \
  --skip

# GroupPermission
docker-compose run --rm web rails generate model GroupPermission \
  group:references \
  resource_type:string \
  resource_id:integer \
  permission:string \
  --skip

# Exécuter les migrations
echo "Exécution des migrations..."
docker-compose run --rm web rails db:migrate

# Charger les données initiales
echo "Chargement des données initiales..."
docker-compose run --rm web rails db:seed

# Installer Active Storage
echo "Installation d'Active Storage..."
docker-compose run --rm web rails active_storage:install
docker-compose run --rm web rails db:migrate

# Configurer Sidekiq
echo "Configuration de Sidekiq..."
docker-compose run --rm web sh -c "cat > config/sidekiq.yml << 'EOF'
:concurrency: 5
:max_retries: 3
:queues:
  - default
  - mailers
  - active_storage_analysis
  - active_storage_purge
  - document_processing
  - ocr_processing
EOF"

echo ""
echo "=== Installation terminée ! ==="
echo ""
echo "Pour démarrer l'application :"
echo "  docker-compose up"
echo ""
echo "L'application sera accessible sur http://localhost:3000"
echo ""
echo "Compte administrateur :"
echo "  Email: admin@docusphere.fr"
echo "  Mot de passe: password123"
echo ""