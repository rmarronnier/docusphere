# 🚀 Guide de Lancement Rapide pour Démo

## ⚡ Stratégie de Démo Sécurisée (30 minutes)

### 1. Arrêt et Nettoyage (2 min)
```bash
# Arrêter tous les containers
docker-compose down

# Nettoyer les volumes pour repartir propre
docker-compose down -v

# Supprimer les logs d'erreur
rm -rf log/*.log
rm -rf tmp/screenshots/*
```

### 2. Reconstruction Propre (5 min)
```bash
# Rebuild sans cache pour éviter les problèmes
docker-compose build --no-cache web

# Démarrer en mode production-like
docker-compose up -d
```

### 3. Setup Base de Données Propre (3 min)
```bash
# Créer et migrer la DB
docker-compose run --rm web rails db:create
docker-compose run --rm web rails db:migrate

# NE PAS lancer tous les seeds - seulement l'essentiel
docker-compose run --rm web rails db:seed:essential
```

### 4. Création de Données de Démo Minimales (5 min)
```bash
# Script de démo léger
docker-compose run --rm web rails runner 'load "db/demo_minimal.rb"'
```

### 5. Tests de Santé Rapides (2 min)
```bash
# Vérifier que l'app répond
curl -I http://localhost:3000

# Vérifier les services
docker-compose ps

# Logs rapides
docker-compose logs --tail=50 web
```

## 🛡️ Parcours de Démo Sécurisé

### Ordre des Fonctionnalités (du plus stable au plus risqué)

1. **Connexion et Navigation** ✅ (Très stable)
   - Login avec admin@docusphere.fr / password123
   - Navigation dans les menus
   - Affichage du dashboard

2. **Gestion des Espaces** ✅ (Stable)
   - Créer un espace
   - Navigation dans les dossiers
   - Affichage de la grille

3. **Upload de Documents** ⚠️ (Risque moyen)
   - Utiliser les fichiers dans `/storage/sample_documents/`
   - Upload simple fichier d'abord
   - Éviter le multi-upload si problème

4. **ImmoPromo - Projets** ✅ (Stable)
   - Liste des projets
   - Création d'un projet simple
   - Timeline et phases

5. **Documents dans ImmoPromo** ⚠️ (Nouveau - risque)
   - Garder pour la fin
   - Avoir un plan B (montrer les maquettes)

## 🚨 Plans de Secours

### Si erreur 500 sur une page :
```bash
# Redémarrer rapidement
docker-compose restart web

# Dire : "Un instant, je vais rafraîchir le service pour optimiser les performances"
```

### Si upload ne fonctionne pas :
- Montrer les documents déjà uploadés
- Expliquer le workflow sans faire l'upload
- "Pour gagner du temps, j'ai préparé des documents"

### Si la DB est corrompue :
```bash
# Reset rapide (30 secondes)
docker-compose run --rm web rails db:reset DISABLE_DATABASE_ENVIRONMENT_CHECK=1
docker-compose run --rm web rails db:seed:essential
```

## 📋 Checklist Pré-Démo

- [ ] Docker Desktop lancé et stable
- [ ] Aucun autre service sur port 3000
- [ ] Dossier `/storage/sample_documents/` présent
- [ ] Terminal prêt avec commandes de secours
- [ ] Navigateur en navigation privée
- [ ] Désactiver les extensions navigateur
- [ ] Avoir DEMO.md ouvert comme référence

## 🎯 Données de Démo Prêtes

### Comptes disponibles :
- **Admin** : admin@docusphere.fr / password123
- **Manager** : manager@docusphere.fr / password123
- **User** : user@docusphere.fr / password123

### Projets de démo :
- "Résidence Les Jardins" - En cours
- "Tour Horizon" - Planification

### Documents prêts :
- Permis de construire
- Plans architecturaux
- Devis construction
- Rapports techniques

## ⏱️ Timing Optimal

1. **00-05 min** : Introduction et connexion
2. **05-10 min** : GED basique (espaces, dossiers)
3. **10-20 min** : ImmoPromo (projets, phases, stakeholders)
4. **20-25 min** : Intégration documents (si stable)
5. **25-30 min** : Questions et conclusion

## 🔥 Commandes d'Urgence

```bash
# Si tout plante - reset complet (2 min)
docker-compose down && docker-compose up -d && docker-compose run --rm web rails db:setup

# Si seulement l'UI bug - vider le cache
docker-compose run --rm web rails tmp:clear
docker-compose run --rm web rails assets:precompile

# Si problème de permissions
docker-compose run --rm web chown -R www-data:www-data storage/
```

---

💡 **Conseil** : Gardez ce guide ouvert dans un onglet pendant la démo !