# 👥 Profils Utilisateurs et Personas

## 📋 Table des Matières

1. [Matrice des Profils](#matrice-des-profils)
2. [Personas Détaillés](#personas-détaillés)
3. [Besoins par Profil](#besoins-par-profil)
4. [Permissions et Accès](#permissions-et-accès)

## 🎯 Matrice des Profils

### Vue d'ensemble des Profils Système

| Profil | Rôle Système | Modules Principaux | Actions Prioritaires | Besoins Spécifiques |
|--------|--------------|-------------------|---------------------|---------------------|
| **Direction Générale** | `super_admin` | Tous modules | Validations stratégiques, Monitoring global | Vue consolidée, KPIs temps réel, Alertes critiques |
| **Chef de Projet** | `admin` + Immo::Promo | GED, Immo::Promo | Coordination, Planning, Assignations | Timeline projet, Kanban tâches, Ressources |
| **Juriste Immobilier** | `manager` | GED, Permis, Contrats | Validations juridiques, Veille | Conformité, Échéancier légal, Archives |
| **Architecte** | `manager` externe | GED technique, Plans | Upload plans, Validations techniques | Versionning plans, Échanges BET, Modifications |
| **Commercial** | `manager` | Commercial, CRM | Réservations, Contrats vente | Pipeline, Stock temps réel, Objectifs |
| **Contrôleur Gestion** | `manager` | Financier, Reporting | Validation factures, Analyse | Budgets, Variances, Tableaux de bord |
| **Expert Technique** | `user` externe | GED technique limitée | Upload études, Consultations | Documents mission, Échanges architecte |
| **Assistant RH** | `user` | RH, Certifications | MAJ certifications, Contrats | Alertes renouvellement, Suivi intervenants |
| **Communication** | `user` | Marketing, Médias | Upload visuels, Validations | Médiathèque, Partage externe, Branding |
| **Admin Système** | `admin` | Administration | Gestion utilisateurs, Config | Monitoring, Logs, Permissions, Maintenance |

## 🎭 Personas Détaillés

### 👔 Marie Dupont - Directrice Générale

**Profil Système :** `direction`

**Informations générales :**
- **Âge** : 52 ans
- **Expérience** : 25 ans dans l'immobilier
- **Formation** : École de commerce + expertise métier
- **Localisation** : Bureau direction, déplacements fréquents

**Objectifs principaux :**
- Surveiller la santé globale des projets
- Anticiper les risques stratégiques
- Valider les décisions importantes (>50k€)
- Maintenir la vision d'ensemble du portefeuille

**Frustrations actuelles :**
- Trop de clics pour accéder aux KPIs essentiels
- Pas de vue consolidée multi-projets
- Alertes critiques noyées dans les notifications
- Rapports trop détaillés, manque de synthèse

**Besoins critiques :**
- Dashboard exécutif avec drill-down intelligent
- Alertes configurables avec seuils personnalisés
- Accès rapide aux documents de validation
- Vue portfolio avec statuts temps réel
- Mobile-first pour consultations nomades

**Widgets privilégiés :**
- Portfolio Overview (2x2) - Vue consolidée projets
- Financial Summary (1x1) - KPIs financiers clés
- Risk Matrix (1x1) - Risques par niveau
- Pending Approvals (1x2) - Validations en attente

### 🏗️ Thomas Martin - Chef de Projet

**Profil Système :** `chef_projet`

**Informations générales :**
- **Âge** : 38 ans
- **Expérience** : 12 ans en gestion de projet
- **Formation** : Ingénieur BTP + PMP
- **Localisation** : Bureau projet + chantiers

**Objectifs principaux :**
- Livrer les projets dans les délais et budgets
- Coordonner efficacement les équipes internes/externes
- Maintenir la qualité des livrables
- Optimiser les ressources et plannings

**Frustrations actuelles :**
- Navigation complexe entre modules ImmoPromo et GED
- Pas de vue unifiée du statut projet
- Difficultés de suivi temps réel des tâches
- Communication dispersée avec les équipes

**Besoins critiques :**
- Timeline interactive avec dépendances
- Vue Kanban des tâches par phase
- Tableau de bord ressources temps réel
- Communication intégrée équipes
- Alertes proactives sur retards/risques

**Widgets privilégiés :**
- Project Timeline (2x2) - Planning Gantt interactif
- Task Kanban (2x2) - Tâches par statut
- Resource Dashboard (2x1) - Utilisation ressources
- Team Communication (1x2) - Messages équipes
- Document Validation (1x1) - Approbations pendantes

### ⚖️ Sophie Legrand - Juriste Immobilier

**Profil Système :** `juriste`

**Informations générales :**
- **Âge** : 45 ans
- **Expérience** : 18 ans en droit immobilier
- **Formation** : Master Droit immobilier + DESS urbanisme
- **Localisation** : Bureau juridique

**Objectifs principaux :**
- Assurer la conformité réglementaire
- Gérer les échéanciers légaux
- Valider juridiquement les documents
- Maintenir la veille réglementaire

**Frustrations actuelles :**
- Difficultés de suivi des échéances légales
- Documents juridiques dispersés
- Pas d'historique des modifications réglementaires
- Recherche complexe dans les archives

**Besoins critiques :**
- Calendrier légal avec alertes automatiques
- Bibliothèque juridique organisée
- Historique des validations
- Recherche sémantique dans les contrats
- Intégration bases légales externes

**Widgets privilégiés :**
- Legal Calendar (2x1) - Échéancier réglementaire
- Document Library (1x2) - Accès rapide archives
- Compliance Status (1x1) - Statut conformité projets
- Recent Validations (1x1) - Dernières approuvations

### 🎨 David Rousseau - Architecte

**Profil Système :** `architecte`

**Informations générales :**
- **Âge** : 42 ans
- **Expérience** : 15 ans architecture/urbanisme
- **Formation** : École d'architecture + HMONP
- **Localisation** : Agence externe + chantiers

**Objectifs principaux :**
- Gérer les plans et documents techniques
- Coordonner avec les bureaux d'études
- Suivre les validations réglementaires
- Maintenir la cohérence architecturale

**Frustrations actuelles :**
- Versionning complexe des plans
- Échanges difficiles avec les BET
- Pas de vue unifiée des modifications
- Lourdeur administrative des validations

**Besoins critiques :**
- Versionning automatique des plans
- Interface d'échange BET intégrée
- Vue 3D/2D synchronisée
- Workflow validation simplifié
- Historique des modifications

**Widgets privilégiés :**
- Plan Viewer (2x2) - Visualisation plans/maquettes
- Version Control (1x1) - Suivi des versions
- BET Exchange (1x1) - Communications techniques
- Validation Pipeline (2x1) - Statut des approbations

### 💼 Claire Moreau - Commerciale

**Profil Système :** `commercial`

**Informations générales :**
- **Âge** : 33 ans
- **Expérience** : 8 ans vente immobilier
- **Formation** : École de commerce + spécialisation immobilier
- **Localisation** : Bureau commercial + prospection terrain

**Objectifs principaux :**
- Maximiser les ventes et réservations
- Gérer la relation client
- Suivre les objectifs individuels/équipe
- Maintenir le pipeline commercial

**Frustrations actuelles :**
- Stock disponible pas à jour
- Manque de visibilité sur les objectifs
- Outils CRM déconnectés
- Reporting commercial insuffisant

**Besoins critiques :**
- Dashboard commercial temps réel
- Stock disponible par programme
- Pipeline de ventes interactif
- Indicateurs de performance
- Accès mobile optimisé

**Widgets privilégiés :**
- Sales Pipeline (2x2) - Entonnoir de ventes
- Stock Status (1x1) - Disponibilités temps réel
- Performance KPIs (1x1) - Objectifs vs réalisé
- Customer Activity (1x2) - Dernières interactions clients

## 📊 Besoins par Type d'Information

### 🎯 Information Critique (Mise à jour temps réel)
- **Direction** : KPIs financiers, alertes risques majeures
- **Chef Projet** : Retards planning, dépassements budget
- **Juriste** : Échéances légales, non-conformités
- **Commercial** : Stock disponible, opportunités chaudes

### 📈 Information de Suivi (Mise à jour quotidienne)
- **Direction** : Avancement projets, indicateurs équipes
- **Chef Projet** : Utilisation ressources, progression tâches
- **Architecte** : Statut validations, modifications plans
- **Commercial** : Performance vs objectifs, activité pipeline

### 📚 Information de Référence (Mise à jour périodique)
- **Juriste** : Base documentaire, jurisprudence
- **Architecte** : Bibliothèque plans types, normes
- **Expert Technique** : Documentation technique, études

## 🔐 Matrice des Permissions

### Niveaux d'Accès par Profil

| Module/Fonction | Direction | Chef Projet | Juriste | Architecte | Commercial | Contrôleur | Expert Tech | Assistant RH | Communication | Admin |
|-----------------|-----------|-------------|---------|------------|------------|------------|-------------|--------------|---------------|-------|
| **GED Core** | Full | Full | Read/Write | Read/Write | Read | Read/Write | Read | Read/Write | Read/Write | Full |
| **Immo::Promo** | Read | Full | Read/Write | Read | Read/Write | Read/Write | Read | - | - | Full |
| **Validation** | Approve | Create/Review | Approve | Approve | - | Review | - | - | Review | Full |
| **Financier** | Full | Read | Read | Read | Read/Write | Full | - | - | - | Full |
| **Administration** | Read | - | - | - | - | - | - | Read | - | Full |
| **Rapports** | Full | Full | Read | Read | Full | Full | Read | Read | Read | Full |

### Règles Spéciales

1. **Cascade de Validation**
   - Direction : Peut valider tout (>50k€ obligatoire)
   - Chef Projet : Peut valider son périmètre (<50k€)
   - Contrôleur : Peut bloquer toute validation pour audit

2. **Isolation par Projet**
   - Chef Projet : Accès limité à ses projets assignés
   - Commercial : Accès aux programmes de son secteur
   - Expert : Accès aux documents de sa mission

3. **Permissions Temporaires**
   - Expert Technique : Accès limité dans le temps
   - Architecte : Accès étendu pendant phases conception

---

**Navigation :** [← Vue d'ensemble](./00_OVERVIEW.md) | [Architecture →](./02_ARCHITECTURE.md)