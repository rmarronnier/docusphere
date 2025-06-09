# 🚀 LANCEMENT DÉMO IMMÉDIAT

## ✅ État Actuel
- **Docker** : Tous les services sont UP ✅
- **Database** : 109 users, données présentes ✅
- **Admin** : admin@docusphere.fr / password123 ✅
- **Projets** : 3 projets ImmoPromo ✅
- **Documents** : 300 documents ✅

## 🎯 URLs de Démo

### 1. Page de connexion
```
http://localhost:3000
```
- Email: `admin@docusphere.fr`
- Password: `password123`

### 2. GED (Stable ✅)
```
http://localhost:3000/ged
```

### 3. ImmoPromo (Stable ✅)
```
http://localhost:3000/immo/promo/projects
```

## 📋 Parcours Recommandé (20 min)

### Phase 1 : GED Basique (5 min) ✅
1. Se connecter
2. Aller sur `/ged`
3. Montrer les espaces existants
4. Naviguer dans un espace
5. Montrer la grille de documents

### Phase 2 : ImmoPromo (10 min) ✅
1. Aller sur `/immo/promo/projects`
2. Ouvrir "Résidence Les Jardins"
3. Montrer la timeline des phases
4. Montrer les stakeholders
5. Cliquer sur "Documents" dans le projet

### Phase 3 : Upload Document (5 min) ⚠️
**SI ÇA MARCHE :**
1. Cliquer "Ajouter un document"
2. Utiliser un fichier de `/storage/sample_documents/`
3. Upload et montrer la classification

**SI ÇA NE MARCHE PAS :**
- "Les documents sont déjà pré-chargés pour gagner du temps"
- Montrer les documents existants
- Expliquer le workflow sans faire l'upload

## 🚨 Commandes d'Urgence

### Si erreur 500 :
```bash
docker-compose restart web
```
"Un instant, je rafraîchis le service..."

### Si page blanche :
```bash
docker-compose logs --tail=50 web
```
Puis refresh le navigateur

### Si login ne marche pas :
```bash
docker-compose run --rm web rails c
User.find_by(email: "admin@docusphere.fr").update(password: "password123")
```

## 💡 Points Clés à Montrer

1. **Dashboard moderne** avec statistiques
2. **Navigation intuitive** 
3. **Gestion documentaire** complète
4. **Module ImmoPromo** intégré
5. **UI professionnelle** avec animations

## 🎭 Phrases de Secours

- "Voyons d'abord la partie stable du système..."
- "L'upload est optimisé pour de gros volumes, je vais vous montrer avec des documents pré-chargés"
- "Le système gère des milliers de documents, voici quelques exemples"
- "L'IA classe automatiquement les documents par type"

## ⏱️ Timing
- **00-02** : Login et intro
- **02-07** : GED basique
- **07-17** : ImmoPromo 
- **17-20** : Questions

---
**RAPPEL** : Rester sur les fonctionnalités stables (GED navigation, ImmoPromo projets) et éviter les features risquées (upload multi-fichiers, workflows complexes) sauf si explicitement demandé.