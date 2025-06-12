# 🌱 Guide du Système de Seeds Avancé

## Vue d'ensemble

Le système de seeds avancé permet de générer un environnement de test réaliste avec :
- 👥 Nombreux utilisateurs avec profils métier variés
- 📄 Documents de formats différents téléchargés depuis le web
- 🏗️ Projets immobiliers complets avec phases et intervenants
- 🔄 Workflows de validation et partages
- 🔔 Notifications et activité récente

## 🚀 Utilisation Rapide

### 1. Génération complète (recommandé pour tests)

```bash
# Génération avec téléchargement de fichiers réels
docker-compose run --rm web rake seed:advanced

# Ou avec le seeds.rb
docker-compose run --rm web rake db:seed USE_ADVANCED_SEED=true
```

### 2. Génération rapide sans téléchargement

```bash
# 10 utilisateurs, 5 docs chacun, pas de téléchargement
docker-compose run --rm web rake seed:quick
```

### 3. Environnement de démonstration

```bash
# Configuration optimisée pour les démos commerciales
docker-compose run --rm web rake seed:demo
```

## ⚙️ Options de Configuration

Vous pouvez personnaliser la génération avec des variables d'environnement :

```bash
# Exemple personnalisé
docker-compose run --rm web rake seed:advanced \
  USERS_COUNT=100 \
  DOCS_PER_USER=30 \
  PROJECTS_COUNT=15 \
  ENABLE_WORKFLOWS=true \
  ENABLE_NOTIFICATIONS=true \
  DOWNLOAD_FILES=true
```

### Variables disponibles

| Variable | Défaut | Description |
|----------|---------|-------------|
| `USERS_COUNT` | 50 | Nombre d'utilisateurs à créer |
| `DOCS_PER_USER` | 20 | Documents par utilisateur (5-20) |
| `PROJECTS_COUNT` | 10 | Nombre de projets immobiliers |
| `ENABLE_WORKFLOWS` | true | Créer des workflows de validation |
| `ENABLE_NOTIFICATIONS` | true | Créer des notifications |
| `DOWNLOAD_FILES` | true | Télécharger des fichiers réels du web |

## 📊 Données Générées

### Utilisateurs

Répartition par département :
- 10% Direction
- 20% Chefs de projet
- 15% Commercial
- 25% Technique
- 10% Juridique
- 10% Finance
- 10% Autres

Chaque utilisateur a :
- Email professionnel réaliste
- Profil métier avec spécialisations
- Téléphone fixe et mobile
- Localisation bureau

### Documents

Types de fichiers variés :
- **PDF** : Rapports, guides, documentation
- **Images** : Plans, photos chantier, rendus 3D
- **Office** : Excel (budgets), Word (contrats)
- **Texte** : Notes techniques, spécifications
- **CAD** : Plans AutoCAD (simulés)
- **Vidéos** : Visites virtuelles, time-lapse
- **Archives** : Dossiers compressés

### Projets Immobiliers

Projets réalistes avec :
- Types variés : résidentiel, bureaux, commercial, mixte
- Budgets de 25M€ à 200M€
- 8 phases par projet (études → réception)
- Intervenants : architectes, entreprises, ingénieurs
- Documents liés par phase

### Structure de Dossiers

Organisation professionnelle :
```
Direction Générale/
  ├── Stratégie/
  ├── Rapports CA/
  └── Conformité/
Projets/
  ├── Résidence Les Jardins/
  ├── Tour Horizon/
  └── Centre Commercial/
Commercial/
  ├── Propositions/
  ├── Contrats/
  └── Clients/
Technique/
  ├── Plans/
  ├── Études/
  └── Normes/
...
```

## 🔍 Vérification des Données

### Voir les statistiques

```bash
docker-compose run --rm web rake seed:stats
```

### Comptes de Test

Après génération, des comptes sont disponibles :
- **Direction** : marie.dubois@horizon.fr
- **Chef Projet** : pierre.martin@horizon.fr  
- **Commercial** : sophie.laurent@horizon.fr
- **Juridique** : francois.moreau@horizon.fr

**Mot de passe** : `password123` pour tous

## 🧹 Maintenance

### Nettoyer les fichiers temporaires

```bash
docker-compose run --rm web rake seed:cleanup
```

### Réinitialiser et regénérer

```bash
# ⚠️ SUPPRIME TOUTES LES DONNÉES
docker-compose run --rm web rake seed:reset_and_seed
```

## 🐛 Dépannage

### Problème de téléchargement

Si les téléchargements échouent, le système crée automatiquement des fichiers placeholder. Pour désactiver le téléchargement :

```bash
docker-compose run --rm web rake seed:advanced DOWNLOAD_FILES=false
```

### Erreurs de validation

Si des erreurs de validation surviennent, vérifiez :
1. Les associations requises (organization, user)
2. Les enums valides
3. Les contraintes uniques

### Performance

Pour de gros volumes :
```bash
# Utiliser les jobs asynchrones
docker-compose run --rm web sidekiq &
docker-compose run --rm web rake seed:advanced
```

## 📝 Exemples d'Utilisation

### Test de charge

```bash
# 200 utilisateurs, beaucoup de documents
docker-compose run --rm web rake seed:advanced \
  USERS_COUNT=200 \
  DOCS_PER_USER=50 \
  DOWNLOAD_FILES=false
```

### Test fonctionnel minimal

```bash
# Juste l'essentiel pour tester
docker-compose run --rm web rake seed:quick
```

### Démo client avec données réalistes

```bash
# Configuration équilibrée avec vrais fichiers
docker-compose run --rm web rake seed:demo
```

## 🎯 Best Practices

1. **Développement** : Utilisez `seed:quick` pour itérer rapidement
2. **Tests E2E** : Utilisez `seed:advanced` avec paramètres moyens
3. **Démos** : Utilisez `seed:demo` pour des données propres
4. **Performance** : Désactivez `DOWNLOAD_FILES` pour accélérer

## 🔗 Ressources

- [RealisticDataGenerator](/app/services/realistic_data_generator.rb) : Génération de données métier
- [SampleFilesDownloader](/app/services/sample_files_downloader.rb) : Téléchargement fichiers
- [AdvancedSeedGenerator](/app/services/advanced_seed_generator.rb) : Orchestration globale