# Plan de Correction des Tests Système - DocuSphere

## 🎯 Objectif
Corriger tous les tests système pour qu'ils passent à 100%, en suivant un processus strict et documenté.

## 📋 Règles Fondamentales

### 1. ❌ NE JAMAIS MODIFIER LES TESTS
- Les tests système documentent le comportement attendu de l'application
- Si un test échoue, c'est l'implémentation qui doit être corrigée
- Si le test est manifestement mal conçu, STOP et attendre les instructions

### 2. ✅ TOUJOURS CRÉER/VÉRIFIER LES TESTS UNITAIRES
- Pour chaque fichier modifié, vérifier qu'un test unitaire existe
- Le test unitaire doit couvrir le cas d'erreur détecté
- Si nouveau fichier créé → test obligatoire immédiat

### 3. 📝 DOCUMENTER CHAQUE CORRECTION
- Mettre à jour PROJECT_STATUS.md après chaque test réussi
- Mettre à jour toute documentation impactée
- Tracer les modifications dans ce document

## 🔄 Processus de Correction

### Étape 1 : Exécution du Test
```bash
./bin/system-test spec/system/[fichier_test].rb
```

### Étape 2 : Analyse de l'Erreur
1. Identifier le type d'erreur :
   - Élément manquant (bouton, lien, formulaire)
   - Route manquante
   - Contrôleur/action manquant
   - Vue/partial manquant
   - Composant ViewComponent manquant
   - Logique métier incorrecte

2. Décision :
   - Si erreur d'implémentation → Continuer étape 3
   - Si test mal conçu → STOP et signaler

### Étape 3 : Correction
1. Implémenter la correction dans le code
2. NE PAS toucher au test système
3. Si nouveau fichier → créer immédiatement son test

### Étape 4 : Vérification Tests Unitaires
Pour chaque fichier modifié :
1. Vérifier l'existence du test unitaire
2. S'assurer que le test couvre le cas d'erreur
3. Ajouter le test si manquant
4. Exécuter le test unitaire

### Étape 5 : Re-exécution Test Système
```bash
./bin/system-test spec/system/[fichier_test].rb
```
- Si succès → Étape 6
- Si échec → Retour Étape 2

### Étape 6 : Documentation
1. Mettre à jour PROJECT_STATUS.md
2. Mettre à jour ce document (section Progression)
3. Mettre à jour autre documentation si nécessaire

## 📊 Tests à Corriger

### 1. Tests Document Actions (6 fichiers)
- [ ] `document_upload_spec.rb`
- [ ] `document_viewing_spec.rb`
- [ ] `document_management_spec.rb`
- [ ] `document_sharing_collaboration_spec.rb`
- [ ] `document_search_discovery_spec.rb`
- [ ] `document_workflow_automation_spec.rb`

### 2. Tests User Journeys (5 fichiers)
- [ ] `direction_journey_spec.rb`
- [ ] `chef_projet_journey_spec.rb`
- [ ] `commercial_journey_spec.rb`
- [ ] `juridique_journey_spec.rb`
- [ ] `cross_profile_collaboration_spec.rb`

## 🚀 Ordre de Priorité

### Phase 1 : Infrastructure de Base
1. `document_upload_spec.rb` - Fonctionnalité fondamentale
2. `document_viewing_spec.rb` - Consultation documents
3. `document_management_spec.rb` - Gestion basique

### Phase 2 : Fonctionnalités Avancées
4. `document_sharing_collaboration_spec.rb` - Partage
5. `document_search_discovery_spec.rb` - Recherche
6. `document_workflow_automation_spec.rb` - Workflows

### Phase 3 : Parcours Métier
7. `direction_journey_spec.rb`
8. `chef_projet_journey_spec.rb`
9. `commercial_journey_spec.rb`
10. `juridique_journey_spec.rb`
11. `cross_profile_collaboration_spec.rb`

## 📈 Progression

### Corrections Effectuées

#### Date : [À REMPLIR]
**Test** : [nom_du_test]
**Status** : ✅ Réussi / ❌ Bloqué
**Modifications** :
- Fichier : [chemin/fichier.rb]
  - Description : [ce qui a été corrigé]
  - Test unitaire : [✅ existant / ✅ créé / ❌ à créer]
- Fichier : [autre fichier si nécessaire]
  - Description : [correction]
  - Test unitaire : [status]

**Documentation mise à jour** :
- [ ] PROJECT_STATUS.md
- [ ] Autre : [préciser]

---

## 🔍 Patterns Communs d'Erreurs

### 1. Routes Manquantes
- **Symptôme** : ActionController::RoutingError
- **Solution** : Ajouter route dans config/routes.rb
- **Test unitaire** : spec/routing/*_routing_spec.rb

### 2. Actions Contrôleur Manquantes
- **Symptôme** : AbstractController::ActionNotFound
- **Solution** : Implémenter action dans contrôleur
- **Test unitaire** : spec/controllers/*_controller_spec.rb

### 3. Vues Manquantes
- **Symptôme** : ActionView::MissingTemplate
- **Solution** : Créer vue ou utiliser format JSON
- **Test unitaire** : Test contrôleur avec format

### 4. Composants ViewComponent Manquants
- **Symptôme** : NameError (uninitialized constant)
- **Solution** : Créer composant ViewComponent
- **Test unitaire** : spec/components/*_component_spec.rb

### 5. Permissions Pundit
- **Symptôme** : Pundit::NotAuthorizedError
- **Solution** : Ajuster policy ou créer policy manquante
- **Test unitaire** : spec/policies/*_policy_spec.rb

### 6. Modèles/Associations Manquants
- **Symptôme** : NoMethodError sur modèle
- **Solution** : Ajouter méthode/association
- **Test unitaire** : spec/models/*_spec.rb

## ⚠️ Points d'Attention

1. **Selenium** : S'assurer que le service Selenium est lancé
2. **JavaScript** : Certains tests nécessitent js: true
3. **Factories** : Vérifier que les factories créent des données valides
4. **Transactions** : Certains tests peuvent nécessiter use_transactional_fixtures: false
5. **ActionCable** : Tests temps réel nécessitent configuration spéciale

## 🛠️ Commandes Utiles

```bash
# Lancer un test spécifique
./bin/system-test spec/system/document_actions/document_upload_spec.rb

# Lancer un exemple spécifique
./bin/system-test spec/system/document_actions/document_upload_spec.rb:42

# Mode debug avec browser visible
DEBUG=1 ./bin/system-test spec/system/document_actions/document_upload_spec.rb

# Voir les logs Selenium
docker-compose logs -f selenium

# Console Rails pour debug
docker-compose run --rm web rails c
```

## 📝 Notes de Suivi

[Cette section sera mise à jour au fur et à mesure des corrections]