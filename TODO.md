# TODO

Supprime chaque partie lorsqu'elle est implémentée.

# Menu utilisateur complet pour app et engine

déconnexion, informations , édition et configuration, notifications avec pastille nombre non lues) dans barre navigation

# Notifications

Developper un systeme de notifications complet pour l'app et surtout pour l'engine, ou l'utilisateur pourra voir les notifications d'evenement qui le concerne (avec un ou des liens dans le message vers le document ou ressource impliquée ou utilisateur ou groupe etc)

# Gestion documents dans l'engine

Les documents doivent avoir une place centrale dans Immo Promo. Les workflows doivent centrer leur interface sur le ou les docs qui le concernent (permis de construire ou plan par exemple). Preview et vignette, lien de téléchargement, infos sur qui la déposé, autorisations qui peut le modifier, actions pour le partager etc.
Il faut se servire des fonctionnalités de la GED déjà développées.
Télécharger sur le web des exemples de docs liés a l'immobilier, permis de construire, pla,n, photos etc. Ces ressources seront ajoutées au .gitignore et serviront au développement local. pas de problématique liées au droit d'auteur. Plus tu téléchargeras de documents, mieux ce sera pour les seeds et les tests.

# workflows

Il faut pouvoir tester des scénarios de workflows complexes impliquant des utilisateurs au roles differents, des documents et actions diverses, l'enchainement de workflows, la verification que l'ui reflete ce qui est attendu (notifications, toast, alerte), presence ou non d'elements etc. Soit imaginatif et ambitieux (quitte a devoir creer des fonctionnalités et modifier l'existant). Quand tous ces tests systems sont écris, fais les modifications, ajout, corrections pour que tout passe.

# Amélioration UI
Sert toi des tests systems de l'engine pour prendre des capture d'écran, analyser ce que tu vois et améliore l'UI pour avoir un résultat professionnel très abouti. Passe autant de temps que nécessaire. C'est très important.

# Nettoyage du repo
Parcours tout les fichiers et supprime ce qui est devenu inutile.

# dashboard superadmin

Gestion des utilisateurs et groupes (CRUD)
Gestion des permissions et authorization
Mise en mode maintenance de l'application
System de feature flag
Page pour consulter les logs d'erreur
Envoi de message (notification) a certains ou tous les utilisateurs
Settings généraux de l'application
