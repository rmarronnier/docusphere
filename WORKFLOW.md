# WORKFLOW.md - Processus de Développement et Prévention des Régressions

## 🚨 IMPORTANT : Ce document DOIT être lu et suivi à chaque session de développement

## 1. Début de Session - Vérifications Obligatoires

### 1.1 État Initial
```bash

# 2. Lancer TOUS les tests pour établir une baseline
docker-compose run --rm web bundle exec rspec --format progress

# 3. Noter le nombre de tests qui passent/échouent
# ✅ Tests passants : X
# ❌ Tests échouants : Y
# ⏭️  Tests pending : Z
```

### 1.2 Vérifier les Factories
```bash
# Toujours vérifier que les factories sont valides
docker-compose run --rm web bundle exec rspec spec/factories_spec.rb
```

### 1.3 Documenter l'État
- Noter dans le chat l'état initial des tests
- Si des tests échouent déjà, les identifier avant de commencer

## 2. Pendant le Développement

### 2.1 Avant TOUTE Modification de Modèle
1. **Lire le modèle existant** et ses associations
2. **Vérifier le schema.rb** pour les colonnes réelles
3. **Identifier les concerns inclus**
4. **Vérifier les tests existants** du modèle

### 2.2 Ajout/Modification de Colonnes
```bash
# TOUJOURS après une migration :
1. docker-compose run --rm web rails db:migrate
2. docker-compose run --rm web rails db:migrate RAILS_ENV=test
3. Vérifier le schema.rb généré
4. Mettre à jour les factories concernées
5. Lancer les tests du modèle affecté
```

### 2.3 Modification de Concerns
⚠️ **ATTENTION** : Les concerns peuvent affecter PLUSIEURS modèles !

1. **Identifier TOUS les modèles qui incluent le concern** :
```bash
find . -name "*.rb" -type f | xargs grep -l "include NomDuConcern" | grep -v spec
```

2. **Tester TOUS les modèles affectés** :
```bash
# Pour chaque modèle trouvé :
docker-compose run --rm web bundle exec rspec spec/models/[modele]_spec.rb
```

### 2.4 Règles d'Or
- **NE JAMAIS** supposer qu'un attribut existe - vérifier dans schema.rb
- **NE JAMAIS** changer un concern sans tester TOUS les modèles qui l'utilisent
- **NE JAMAIS** ignorer un test qui échoue "temporairement"

## 3. Avant de Committer

### 3.1 Tests Obligatoires
```bash
# 1. Tests des modèles modifiés
docker-compose run --rm web bundle exec rspec spec/models/

# 2. Tests des factories
docker-compose run --rm web bundle exec rspec spec/factories_spec.rb

# 3. Tests des concerns si modifiés
docker-compose run --rm web bundle exec rspec spec/models/concerns/
```

### 3.2 Vérification Finale
- Le nombre de tests qui passent doit être ≥ au nombre initial
- Aucun nouveau test ne doit échouer
- Les factories doivent toutes être valides

## 4. Patterns Courants et Pièges

### 4.1 Concern Authorizable
- Utilise `owned_by?` qui vérifie différents attributs selon le modèle :
  - `user` (cas général)
  - `uploaded_by` (Document)
  - `project_manager` (ImmoPromo)
- Si vous ajoutez un modèle avec propriétaire, mettez à jour `owned_by?`

### 4.2 WorkflowManageable
- Utilisé par ImmoPromo (Permit, Phase, Task)
- Incompatible avec le modèle Workflow qui utilise AASM
- Utilise des statuts différents : pending, in_progress, completed, cancelled

### 4.3 PaperTrail et Versioning
- Document utilise PaperTrail pour le versioning
- NE PAS créer de modèle DocumentVersion
- Utiliser `document.versions` pour accéder aux versions

### 4.4 Associations Polymorphiques
- Vérifier que les deux côtés de l'association sont corrects
- Les factories doivent utiliser le bon type polymorphe

## 5. En Cas de Régression

### 5.1 Diagnostic Rapide
1. Identifier le commit qui a introduit la régression
2. Lister TOUS les fichiers modifiés
3. Pour chaque modèle/concern modifié, vérifier les dépendances

### 5.2 Correction
1. NE PAS paniquer et faire des changements partout
2. Corriger UN problème à la fois
3. Lancer les tests après CHAQUE correction
4. Documenter la correction dans le commit

## 6. Documentation Obligatoire

### 6.1 Après Ajout de Fonctionnalité
- Mettre à jour MODELS.md si nouveau modèle/association
- Mettre à jour TODO.md pour retirer les tâches complétées
- Documenter dans CLAUDE.md si comportement spécifique

### 6.2 Après Correction de Bug
- Noter dans CLAUDE.md si le bug peut se reproduire
- Ajouter un test pour éviter la régression

## 7. Checklist Fin de Session

- [ ] Tous les tests passent ou le nombre d'échecs est documenté
- [ ] Les factories sont toutes valides
- [ ] Les fichiers MD sont à jour
- [ ] Aucune modification temporaire n'est laissée dans le code
- [ ] Le schema.rb est cohérent avec les migrations

## 8. Commandes Utiles Récapitulatives

```bash
# Tests complets
docker-compose run --rm web bundle exec rspec

# Tests d'un modèle spécifique
docker-compose run --rm web bundle exec rspec spec/models/document_spec.rb

# Tests avec fail-fast (arrêt au premier échec)
docker-compose run --rm web bundle exec rspec --fail-fast

# Vérifier les associations d'un modèle dans la console
docker-compose run --rm web rails console
> Document.reflect_on_all_associations.map(&:name)

# Trouver tous les usages d'un concern
find . -name "*.rb" -type f | xargs grep -l "include ConcernName" | grep -v spec
```

---

**⚠️ CE WORKFLOW EST OBLIGATOIRE - Le suivre évite 90% des régressions !**
