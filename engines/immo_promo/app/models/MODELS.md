# Models - Module ImmoPromo

## 📊 ApplicationRecord
**Finalité**: Classe de base pour tous les modèles du module ImmoPromo. Configure le namespace et les comportements par défaut.

**Pièges/Particularités**:
- Classe abstraite dans le module Immo::Promo
- Hérite du ApplicationRecord principal

---

## 🏗️ Project
**Finalité**: Entité centrale représentant un projet immobilier complet. Gère le cycle de vie de la planification à la livraison. Coordonne phases, budgets, intervenants et documentation. Suit l'avancement global et les métriques financières. Support multi-types: résidentiel, commercial, mixte, industriel, rénovation.

**Pièges/Particularités**:
- Modèle central avec 20+ associations (risque de charge)
- Calculs complexes (rentabilité, surface totale) sans cache
- `project_type` et `status` en enum mais sans state machine
- Pas de validation des dates (end > start)
- Monétisation par défaut en EUR non configurable

**Évolutions suggérées**:
- Implémenter state machine pour transitions de status
- Ajouter counter caches (lots_count, completed_tasks_count)
- Extraire calculs financiers dans service
- Valider cohérence temporelle start/end dates
- Permettre configuration devise

**Utile à savoir**:
- Utilise `audited` pour historique
- Concern Documentable pour gestion docs
- Scopes métier: active, delayed, by_type

---

## 📅 Phase
**Finalité**: Étape majeure d'un projet immobilier (conception, permis, construction, etc.). Organise les tâches en groupes logiques. Gère les dépendances entre phases et le chemin critique. Track l'avancement et les jalons. Supporte 8 types de phases standards.

**Pièges/Particularités**:
- `phase_type` enum avec valeurs hardcodées
- Pas de validation contre dépendances circulaires
- Méthode `can_start?` vérifie prerequisites mais pas les dates
- `critical_path` booléen manuel (devrait être calculé)

**Évolutions suggérées**:
- Calculer automatiquement le chemin critique
- Valider graph de dépendances (pas de cycles)
- Ajouter templates de phases par type de projet
- Notifications auto quand phase peut démarrer

---

## ✅ Task
**Finalité**: Unité de travail assignable dans une phase. Gère l'assignation aux intervenants et le suivi temporel. Supporte dépendances entre tâches et criticité. Track effort estimé vs réel. Intègre documents et livrables.

**Pièges/Particularités**:
- `assigned_to` polymorphe (User ou Stakeholder) complexifie queries
- Pas de validation effort réel <= estimé * X
- Priority string au lieu d'integer
- Dépendances sans vérification de cohérence

**Évolutions suggérées**:
- Unifier assignation (toujours via Stakeholder?)
- Implémenter Gantt/PERT pour scheduling
- Alertes automatiques pour dépassements
- Intégrer avec calendriers externes

---

## 👤 Stakeholder
**Finalité**: Intervenant sur un projet (architecte, entreprise, bureau d'études, etc.). Centralise contacts, documents et qualifications. Track participation aux tâches et performance. Gère les types d'intervenants et leurs spécialités. Support évaluation qualité et coûts.

**Pièges/Particularités**:
- Mélange personne physique et morale
- `performance_rating` calculé à la volée (pas de cache)
- Pas de gestion des conflits d'intérêts
- Contact info non structurée (JSON préférable)

**Évolutions suggérées**:
- Séparer Person et Company
- Cache pour performance metrics
- Gestion des habilitations/certifications
- Intégration annuaire entreprises

**Utile à savoir**:
- Concern Addressable pour géolocalisation
- Relation M2M avec projets via tasks
- Support pour évaluations par projet

---

## 📋 Permit
**Finalité**: Gestion des autorisations administratives (permis de construire, déclaration préalable, etc.). Track statut, conditions et échéances. Génère alertes pour deadlines réglementaires. Centralise documents officiels et correspondances. Gère recours et modifications.

**Pièges/Particularités**:
- `conditions` en text au lieu de modèle dédié
- Dates critiques sans jobs de notification
- Status sans workflow (draft→submitted→approved)
- Pas de gestion des versions/modificatifs

**Évolutions suggérées**:
- Modéliser PermitCondition proprement
- Jobs pour alertes J-30, J-7
- State machine avec callbacks
- Historique des modifications
- Intégration APIs administration

---

## 💰 Budget & BudgetLine
**Finalité**: Gestion financière détaillée des projets. Budget gère versions (initial, révisé, final) et scénarios (optimiste, pessimiste). BudgetLine détaille par poste/sous-poste avec suivi réalisé. Support analyses d'écarts et projections. Alertes sur dépassements.

**Pièges/Particularités**:
- Monétisation EUR hardcodée
- Calculs variance dans le modèle (non cachés)
- Pas de validation planned >= 0
- Manque workflow validation budgétaire

**Évolutions suggérées**:
- Service pour calculs complexes
- Versioning propre des budgets
- Workflow approbation avec seuils
- Export vers outils comptables
- Multi-devise si international

**Utile à savoir**:
- Money-rails pour montants
- Scopes pour analyses (over_budget, etc.)
- Categories/subcategories libres

---

## 📄 Contract
**Finalité**: Gestion des contrats avec les intervenants. Track montants, échéances et paiements. Gère avenants et pénalités. Suit statut de négociation à clôture. Centralise documents contractuels.

**Pièges/Particularités**:
- `amendments` en JSON non structuré
- Pas de gestion des signatures
- Status sans transitions validées
- Calcul paid_percentage sans arrondi

**Évolutions suggérées**:
- Modèle Amendment séparé
- Intégration signature électronique
- Workflow avec jalons paiement
- Alertes échéances automatiques

---

## 🏠 Lot & LotSpecification
**Finalité**: Lot représente une unité vendable (appartement, parking, etc.). Track surface, prix et statut commercial. LotSpecification détaille caractéristiques (nb pièces, orientation, etc.). Support réservations et ventes. Calculs de rentabilité.

**Pièges/Particularités**:
- `specification_type` enum non déclaré dans LotSpecification
- Relations lot ↔ réservations mal gérées
- Prix sans historique

**Évolutions suggérées**:
- Historique des prix
- Gestion des options/variantes
- Configurateur 3D
- Scoring attractivité

---

## 📝 Reservation
**Finalité**: Gestion des réservations de lots. Track client, dépôt et échéance. Gère expiration automatique et conversion en vente. Support annulations et transferts.

**Pièges/Particularités**:
- Client non lié au modèle User
- Pas de workflow état
- `is_expired?` devrait être un scope

**Évolutions suggérées**:
- CRM intégré pour clients
- Workflow réservation→vente
- Documents automatiques (contrat résa)
- Relances automatiques

---

## 🎯 Milestone
**Finalité**: Jalons majeurs du projet immobilier. Définit points de contrôle et livrables attendus. Impact planning global si retard. Génère notifications approche échéance.

**Pièges/Particularités**:
- Pas lié directement aux phases
- `deliverables` en JSON libre
- Manque impact cascade sur planning

**Évolutions suggérées**:
- Lier aux phases
- Modéliser Deliverable
- Calcul impact retard
- Dashboard jalons critiques

---

## ⚠️ Risk
**Finalité**: Gestion des risques projet. Évalue probabilité et impact pour calculer criticité. Track stratégies de mitigation et responsables. Historique des réévaluations.

**Pièges/Particularités**:
- `mitigation_strategies` en array simple
- Score calculé mais pas de seuils définis
- Pas d'historique des évaluations

**Évolutions suggérées**:
- Modèle MitigationAction
- Matrice risques paramétrable
- Alertes sur seuils
- Reporting risques consolidé

---

## 🏢 Certification
**Finalité**: Gestion des certifications des intervenants. Track validité et renouvellements. Alertes expiration. Bloque assignation si certification requise manquante.

**Pièges/Particularités**:
- Type et status enums non déclarés
- Pas de liaison avec compétences requises
- Documents non versionnés

**Évolutions suggérées**:
- Définir CertificationRequirement par type tâche
- Workflow renouvellement
- Intégration organismes certificateurs
- Badges visuels sur profils

---

## ⏱️ TimeLog
**Finalité**: Suivi du temps passé sur les tâches. Calcul coûts réels basés sur taux horaires. Support facturable/non-facturable. Agrégations pour reporting.

**Pièges/Particularités**:
- User direct au lieu de passer par Stakeholder
- Pas de validation heures (ex: max 24h/jour)
- Taux horaire sur le log (devrait être sur user/stakeholder)

**Évolutions suggérées**:
- Taux sur profils utilisateurs
- Validation cohérence temporelle
- Export vers outils facturation
- Approbation manager

---

## 📊 ProgressReport
**Finalité**: Rapports d'avancement périodiques. Consolide métriques à date donnée. Support photos et documents. Diffusion aux parties prenantes.

**Pièges/Particularités**:
- Pas de template/structure
- `issues` et `next_steps` en text libre
- Manque signatures/validations

**Évolutions suggérées**:
- Templates par type projet
- Sections structurées
- Workflow validation
- Génération PDF automatique

---

## 📌 PermitCondition
**Finalité**: Conditions attachées aux permis. Track respect et échéances. Génère non-conformités si non respectées.

**Pièges/Particularités**:
- `condition_type` string libre
- Pas de workflow résolution
- Lien compliance documents flou

**Évolutions suggérées**:
- Types prédéfinis
- Workflow traitement
- Checklist compliance
- Intégration contrôles terrain

---

## 🔄 PhaseSchedulableDependency & TaskDependency
**Finalité**: Gestion des dépendances entre phases et entre tâches. Permet construction du graphe de dépendances. Base pour calcul chemin critique et ordonnancement.

**Pièges/Particularités**:
- Deux modèles pour même concept
- Pas de types de liens (FS, FF, SS, SF)
- Validation anti-cycle manquante

**Évolutions suggérées**:
- Unifier en Dependency polymorphe
- Types de dépendances projet
- Algorithme détection cycles
- Visualisation graphe

---

## 🏆 MitigationAction
**Finalité**: Actions concrètes pour mitiger les risques. Track responsable et échéance. Mesure efficacité post-implémentation.

**Pièges/Particularités**:
- `status` string au lieu d'enum
- Pas de budget associé
- Efficacité non mesurée

**Évolutions suggérées**:
- Enum status avec workflow
- Budget et ROI
- KPIs efficacité
- Templates actions types

---

## 🎨 ProjectWorkflowTemplate  
**Finalité**: Templates réutilisables de workflows projet. Accélère création nouveaux projets. Standardise processus par type.

**Pièges/Particularités**:
- `template_data` JSON non structuré
- Pas utilisé dans le code actuel
- Manque builder pour instanciation

**Évolutions suggérées**:
- DSL pour définir templates
- Versioning templates
- Héritage/composition
- Marketplace templates

---

## 🗓️ ProjectSchedule
**Finalité**: Vue planning consolidée du projet. Agrège phases, tâches et jalons. Support export Gantt et calendriers.

**Pièges/Particularités**:
- Modèle vide actuellement
- Semble prévu mais non implémenté

**Évolutions suggérées**:
- Implémenter génération planning
- Export MS Project/Google Calendar
- Vues filtrées par intervenant
- Optimisation automatique

---

## 💎 Concerns Utilisés

### 📍 Addressable
Ajoute adresse complète avec géocodage potentiel.

### 📅 Schedulable  
Gestion dates début/fin avec validations et helpers.

### 📄 Documentable
Association polymorphe avec documents GED.

### 🔄 WorkflowManageable
Gestion états et transitions (si implémenté).

### 🌳 Treeable
Hiérarchie parent/enfants (peu utilisé ici).