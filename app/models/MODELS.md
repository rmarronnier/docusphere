# Models - Application Principale

## 📁 ApplicationRecord
**Finalité**: Classe de base pour tous les modèles ActiveRecord de l'application. Configure les comportements par défaut.

**Pièges/Particularités**:
- Classe abstraite (`self.abstract_class = true`)
- Étonnamment vide - aucune configuration commune

**Évolutions suggérées**:
- Ajouter des concerns communs (timestamps formatting, etc.)
- Configurer des comportements par défaut (UUID primary keys?)

---

## 👤 User
**Finalité**: Gestion de l'authentification et des autorisations utilisateur. Utilise Devise pour l'authentification. Supporte un système de permissions flexible avec rôles et permissions directes. Appartient obligatoirement à une organisation (multi-tenant). Gère les préférences utilisateur et les associations avec documents, groupes et notifications.

**Pièges/Particularités**:
- Mélange rôles (admin, manager, user) ET permissions granulaires
- `permissions` stocké en Array dans JSON (pas de format standardisé)
- `preferences` en JSONB sans validation de structure
- Callback `setup_default_permissions` non thread-safe
- Pas de validation du format email au-delà de Devise

**Évolutions suggérées**:
- Séparer rôles et permissions dans des modèles distincts
- Créer un PermissionService pour centraliser la logique
- Ajouter validation/schema pour preferences JSON
- Implémenter cache pour les permissions (méthodes appelées fréquemment)

**Utile à savoir**:
- `can?` et `has_permission?` font la même chose
- Les permissions peuvent expirer (`expires_at`)
- Soft delete non implémenté malgré les associations `dependent: :destroy`

---

## 🏢 Organization
**Finalité**: Entité racine du système multi-tenant. Contient tous les espaces, utilisateurs, groupes et workflows. Gère les paramètres globaux et limites de l'organisation. Support pour différents types d'organisations (enterprise, education, government, non_profit, personal).

**Pièges/Particularités**:
- `settings` en JSONB sans schema défini
- Slug généré automatiquement mais pas d'unicité en DB (seulement validation Rails)
- Énorme cascade de `dependent: :destroy` (dangereux!)
- Aucune gestion de soft delete

**Évolutions suggérées**:
- Ajouter index unique sur slug en DB
- Implémenter soft delete pour éviter pertes de données
- Définir schema pour settings (storage_quota_gb, user_limit, etc.)
- Ajouter cache pour les compteurs (storage_used, etc.)

---

## 📄 Document
**Finalité**: Modèle central de la GED gérant fichiers, métadonnées, versions et workflows. Supporte l'upload via ActiveStorage, le versioning avec PaperTrail, le processing IA et OCR. Gère les états (draft, published, archived), les verrouillages et les partages. Inclut la recherche fulltext et la validation collaborative.

**Pièges/Particularités**:
- **580+ lignes** - Modèle obèse nécessitant refactoring urgent
- Double système de versioning: PaperTrail + `has_many :document_versions` (?!)
- États gérés par string `status` au lieu d'AASM
- Processing asynchrone mais pas de gestion d'erreurs robuste
- `lock!` override la méthode ActiveRecord (warning dans les logs)

**Évolutions suggérées**:
- **Urgent**: Choisir UN système de versioning (PaperTrail recommandé)
- Extraire AI processing dans concern ou service
- Implémenter state machine propre (AASM)
- Séparer en plusieurs concerns: Lockable, Shareable, Processable
- Ajouter retry logic pour jobs de processing

**Utile à savoir**:
- `search_data` pour l'indexation Elasticsearch
- Support complet des fichiers Office, PDF, images
- Détection automatique du type MIME
- File d'attente Sidekiq pour processing

---

## 📂 Space
**Finalité**: Container principal pour l'organisation des documents. Équivalent d'un drive ou workspace. Gère les autorisations au niveau space et les quotas de stockage. Support pour espaces publics/privés et archives.

**Pièges/Particularités**:
- `storage_used_cache` pas mis à jour automatiquement
- Pas de validation du storage_quota_gb (peut être négatif)
- Relation polymorphe avec Authorization mais pas d'index

**Évolutions suggérées**:
- Implémenter cache automatique pour storage_used
- Ajouter job de recalcul périodique des quotas
- Index sur les colonnes polymorphes pour Authorization

---

## 📁 Folder
**Finalité**: Organisation hiérarchique des documents au sein d'un space. Utilise le concern Treeable pour gérer l'arborescence parent/enfants. Supporte les métadonnées personnalisées et le calcul récursif de taille.

**Pièges/Particularités**:
- `path` stocké mais recalculé par Treeable (duplication)
- `position` pour l'ordre mais pas d'index composite avec parent_id
- Pas de limite de profondeur d'arborescence

**Évolutions suggérées**:
- Supprimer `path` ou l'utiliser comme cache
- Ajouter index composite [parent_id, position]
- Limiter la profondeur max (performance)

---

## 🏷️ Tag
**Finalité**: Système de tagging scopé par organisation. Permet la catégorisation flexible des documents. Supporte les tags colorés et la recherche par tags.

**Pièges/Particularités**:
- Pas d'index sur [organization_id, name] alors que c'est unique
- `color` non validé (format hexadécimal?)

**Évolutions suggérées**:
- Ajouter index unique composite
- Valider format couleur (#RRGGBB)
- Ajouter counter cache pour usage_count

---

## 🔐 Authorization
**Finalité**: Système flexible d'autorisations pour tous les objets du système. Supporte les permissions temporaires, la révocation et l'audit. Peut être assigné à un utilisateur OU un groupe (XOR).

**Pièges/Particularités**:
- Contrainte XOR (user OU group) validée en Ruby seulement
- `permissions` stocké en Hash dans JSON (inconsistant avec User)
- Pas de cache des permissions actives
- Check constraint en DB mais validation Rails différente

**Évolutions suggérées**:
- Ajouter constraint DB pour XOR
- Standardiser format permissions (Array vs Hash)
- Implémenter cache Redis pour permissions actives
- Créer scope pour permissions non expirées/révoquées

---

## 👥 UserGroup & UserGroupMembership
**Finalité**: Gestion des groupes d'utilisateurs pour permissions collectives. UserGroup définit le groupe avec ses permissions. UserGroupMembership lie les utilisateurs avec leur rôle dans le groupe. Permet la gestion hiérarchique des permissions.

**Pièges/Particularités**:
- UserGroupMembership sans validations (rôle peut être nil)
- Pas de validation d'unicité user/group au niveau DB
- Permissions du groupe non mergées automatiquement

**Évolutions suggérées**:
- Ajouter validations sur membership
- Index unique [user_id, user_group_id]
- Helper pour merger permissions user + groups
- Ajouter rôles prédéfinis (owner, admin, member)

---

## ✅ ValidationRequest & DocumentValidation
**Finalité**: Système de validation collaborative des documents. ValidationRequest orchestre le processus global avec deadline et validateurs multiples. DocumentValidation capture chaque réponse individuelle. Supporte validation parallèle ou séquentielle.

**Pièges/Particularités**:
- Pas de state machine pour le workflow
- `required_validations` vs validations reçues non synchronisé
- Deadline non enforced automatiquement

**Évolutions suggérées**:
- Implémenter AASM pour états
- Job pour auto-expirer après deadline
- Notifications automatiques pour rappels
- Dashboard pour suivre les validations en cours

---

## 🔄 Workflow & WorkflowStep
**Finalité**: Système générique de workflows multi-étapes. Workflow définit le processus global et peut servir de template. WorkflowStep définit chaque étape avec assignation et actions. WorkflowSubmission track l'exécution d'une instance.

**Pièges/Particularités**:
- WorkflowStep `actions` en JSON sans schema
- Pas de validation de l'ordre des steps
- WorkflowSubmission état géré manuellement
- Templates non vraiment implémentés

**Évolutions suggérées**:
- Définir DSL pour actions
- Valider cohérence position/dependencies
- State machine pour submissions
- Builder pattern pour créer depuis template

---

## 🔔 Notification
**Finalité**: Système de notifications multi-canal unifié. Supporte 30+ types d'événements différents. Gère email et in-app, avec préférences utilisateur. Track read/unread et permet actions directes. Archive automatique après lecture.

**Pièges/Particularités**:
- 30+ types hardcodés (difficile à étendre)
- `data` JSON sans schema par type
- Pas de batching pour emails
- Pas de rate limiting

**Évolutions suggérées**:
- Créer classes par type de notification
- Schémas JSON par type
- Implémenter digest emails
- Ajouter rate limiting par user
- Support pour push notifications

---

## 🧺 Basket & BasketItem
**Finalité**: Système de collection temporaire de documents. Permet de grouper des documents pour actions batch. Équivalent d'un panier pour opérations groupées.

**Pièges/Particularités**:
- Pas de limite sur nombre d'items
- Pas d'expiration automatique
- Position dans BasketItem non utilisée

**Évolutions suggérées**:
- Limiter taille max des baskets
- Auto-cleanup après X jours
- Implémenter vraiment l'ordre des items
- Actions batch async via jobs

---

## 🔗 Link
**Finalité**: Système de liens bidirectionnels entre objets. Permet de créer des relations n-n entre tous types d'objets. Supporte métadonnées sur la relation.

**Pièges/Particularités**:
- Relations polymorphes sans index!
- `metadata` JSON sans utilisation visible
- Pas de validation contre liens circulaires

**Évolutions suggérées**:
- **Urgent**: Ajouter index sur colonnes polymorphes
- Définir types de liens (related_to, depends_on, etc.)
- Valider contre boucles infinies
- UI pour visualiser graph de liens

---

## 📊 Metadatum
**Finalité**: Stockage flexible de métadonnées pour tous objets. Système clé-valeur avec types supportés. Alternative à l'ajout de colonnes.

**Pièges/Particularités**:
- Table unique pour TOUTES les métadonnées (perf?)
- Pas d'index sur metadatable_type/id
- value_type non validé

**Évolutions suggérées**:
- Index sur colonnes polymorphes
- Considérer JSONB columns à la place
- Valider types supportés
- Cache pour métadonnées fréquentes

---

## 🔍 SearchQuery
**Finalité**: Historique et analytics des recherches utilisateur. Permet suggestions et amélioration de la recherche.

**Pièges/Particularités**:
- Pas d'anonymisation des données
- Croissance infinie de la table

**Évolutions suggérées**:
- Aggregation périodique
- Suppression après X mois
- Analytics dashboard
- Suggestions basées sur historique

---

## 🎖️ ValidationTemplate
**Finalité**: Templates réutilisables pour processus de validation. Évite de recréer les mêmes workflows.

**Pièges/Particularités**:
- `validation_rules` sans schema
- Pas utilisé dans le code actuel

**Évolutions suggérées**:
- Définir structure validation_rules
- Créer UI pour gérer templates
- Permettre héritage/composition

---

## 📤 Share
**Finalité**: Partage public de ressources via liens uniques. Alternative aux autorisations pour partage externe.

**Pièges/Particularités**:
- Token non sécurisé (juste random hex)
- Pas de rate limiting sur accès

**Évolutions suggérées**:
- Tokens signés cryptographiquement
- Rate limiting par IP
- Analytics sur utilisation
- Support pour passwords sur liens

---

## 💾 MetadataField & MetadataTemplate
**Finalité**: Système de métadonnées structurées avec templates. MetadataTemplate définit un ensemble de champs. MetadataField définit chaque champ avec type et validations. Alternative plus structurée à Metadatum.

**Pièges/Particularités**:
- Deux systèmes de métadonnées en parallèle!
- `validations` et `options` sans schemas
- Pas utilisé dans Document

**Évolutions suggérées**:
- Choisir UN système de métadonnées
- Si gardé: intégrer avec Document
- Définir schemas pour JSON fields
- UI builder pour templates