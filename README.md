# Docusphere - Système de Gestion Électronique de Documents

Docusphere est une application collaborative de gestion documentaire développée avec Ruby on Rails, PostgreSQL, et Docker.

## Fonctionnalités principales

### Gestion des documents
- Support des formats : PDF, PDF/A, Word, Excel, PowerPoint, images, audio, vidéo, email, ZIP
- Import manuel et automatique de documents
- Glisser-déposer pour l'upload
- OCR intégré (Tesseract)
- Fusion et découpage de PDF
- Gestion des versions
- Verrouillage de documents

### Collaboration
- Bannettes personnelles et partagées
- Partage sécurisé de documents
- Workflows de validation
- Notifications en temps réel
- Édition en ligne (type Office 365)

### Organisation
- Espaces thématiques
- Plan de classement hiérarchique
- Métadonnées personnalisables
- Étiquettes (tags)
- Héritage des métadonnées

### Recherche
- Recherche plein texte
- Recherche par métadonnées
- Recherches sauvegardées
- Filtres avancés
- Multi-espaces

### Administration
- Gestion des utilisateurs et groupes
- Permissions granulaires
- Règles de conservation (DUA/DUC)
- Versement automatique SAE (SEDA)
- Statistiques d'utilisation

## Modules Métiers

### ImmoPromo - Gestion de Projets Immobiliers
Module complet de pilotage de projets immobiliers offrant :
- **Gestion de projets** : Planification par phases, suivi des jalons et timeline interactive
- **Gestion des tâches** : Assignations, dépendances et suivi d'avancement
- **Coordination des intervenants** : Gestion des parties prenantes, contrats et certifications
- **Autorisations** : Workflow de permis de construire avec suivi des conditions
- **Suivi financier** : Budgets détaillés avec analyse des écarts
- **Gestion des lots** : Définition des logements et suivi des réservations
- **Gestion des risques** : Identification, évaluation et plans d'atténuation

Accès : `/immo/promo/` (authentification et permissions requises)

## Prérequis

- Docker et Docker Compose
- 4GB de RAM minimum
- 10GB d'espace disque

## Installation

1. Cloner le repository
```bash
git clone [URL_DU_REPO]
cd docusphere
```

2. Lancer le script de configuration initiale
```bash
./setup.sh
```

3. Une fois la construction Docker terminée, finaliser l'installation
```bash
./finalize_setup.sh
```

4. Démarrer l'application
```bash
docker-compose up
```

L'application sera accessible sur http://localhost:3000

**Compte administrateur par défaut :**
- Email : admin@docusphere.fr
- Mot de passe : password123

## Architecture technique

- **Backend** : Ruby on Rails 7.1
- **Frontend** : ViewComponent, Turbo, Stimulus, Tailwind CSS
- **Base de données** : PostgreSQL 15
- **Cache/Queues** : Redis
- **Jobs** : Sidekiq
- **Recherche** : Elasticsearch
- **Stockage** : Active Storage
- **Frontend** : Turbo, Stimulus, Tailwind CSS

## Services Docker

- `web` : Application Rails (port 3000)
- `db` : PostgreSQL (port 5432)
- `redis` : Redis (port 6379)
- `sidekiq` : Worker Sidekiq
- `elasticsearch` : Moteur de recherche (port 9200)

## Développement

### Commandes utiles

```bash
# Accéder à la console Rails
docker-compose run --rm web rails console

# Lancer les tests
docker-compose run --rm web rspec

# Voir les logs
docker-compose logs -f

# Reconstruire les images
docker-compose build
```

### Structure du projet

```
docusphere/
├── app/
│   ├── models/         # Modèles Active Record
│   ├── controllers/    # Contrôleurs
│   ├── views/          # Vues
│   ├── components/     # ViewComponents
│   └── javascript/     # Stimulus controllers
├── config/
│   ├── locales/        # Fichiers de traduction
│   └── database.yml    # Configuration DB
├── db/
│   └── migrate/        # Migrations
└── docker-compose.yml  # Configuration Docker
```

## Licence

Propriétaire - Tous droits réservés