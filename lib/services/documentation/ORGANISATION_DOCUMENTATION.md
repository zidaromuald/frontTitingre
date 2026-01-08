# Organisation de la Documentation

## Vue d'ensemble

La documentation du projet Titingre a été réorganisée en janvier 2026 pour améliorer la navigabilité et la maintenance. Tous les fichiers .md sont maintenant organisés dans des sous-dossiers thématiques.

## Structure des dossiers

### 📦 [deploiement/](deploiement/)
Tout ce qui concerne le déploiement de l'application sur différentes plateformes.
- Configuration Web (VPS Hostinger)
- Configuration Android (Google Play Store)
- Configuration iOS (App Store)
- CORS et backend
- Icônes et assets

**Fichiers : 9**

### 🏗️ [architecture/](architecture/)
Documentation de l'architecture du système et de la logique métier.
- Architecture des services
- Logique des posts et messages
- Conversations bidirectionnelles
- Système de suivi
- Recherche vs services

**Fichiers : 5**

### 🔧 [corrections/](corrections/)
Historique des corrections et fixes de bugs.
- Erreurs Firebase
- Corrections UI
- Fixes de services
- Résolutions de problèmes

**Fichiers : 5**

### 🚀 [implementations/](implementations/)
Plans et documentations des implémentations de features.
- Implémentation groupes
- Implémentation posts et messages
- Contenus non lus
- Transactions et formulaires
- Service plans et options

**Fichiers : 7**

### ✨ [features/](features/)
Documentation des fonctionnalités implémentées.
- Profils dynamiques (User/Société)
- Statistiques
- Validation de fichiers
- Ajout direct abonnés
- Mot de passe oublié
- Résumés et index

**Fichiers : 8**

### 📋 [comparisons/](comparisons/)
Analyses comparatives entre IS (Interface Société) et IU (Interface Utilisateur).
- Comparaison profils
- Comparaison paramètres
- Comparaison transactions
- Historique des modifications
- Validation finale

**Fichiers : 7**

### ⚙️ [setup/](setup/)
Instructions de configuration initiale.
- Firebase setup
- Configuration environnement
- Prérequis et dépendances

**Fichiers : 1**

### 📸 [media/](media/)
Documentation de la gestion des médias et upload.
- Améliorations upload Cloudflare R2
- R2NetworkImage widget
- Compression et optimisation
- ValidationMediaService

**Fichiers : 2 + README**

### 🧹 [cleanup/](cleanup/)
Documentation du nettoyage et refactoring du code.
- Suppression données statiques
- Nettoyage commentaires TODO
- Synthèse du refactoring
- Métriques d'amélioration

**Fichiers : 5 + README**

## Fichiers à la racine de documentation/

### Mapping des services (racine)
Fichiers de mapping détaillant la correspondance entre les services Flutter et les controllers backend NestJS :
- `ABONNEMENT_MAPPING.md`
- `COMMENT_LIKE_MAPPING.md`
- `CONVERSATION_MESSAGE_MAPPING.md`
- `DEMANDE_ABONNEMENT_MAPPING.md`
- `GROUPE_MAPPING.md`
- `POST_MAPPING.md`
- `SOCIETE_MAPPING.md`
- `USER_MAPPING.md`
- `GROUPES_MAPPING.md`
- `SYSTEME_RELATIONS_COMPLET.md`
- `ARCHITECTURE_SERVICES.md`

### Documentation générale (racine)
- `README.md` - Vue d'ensemble complète avec checklist
- `INDEX.md` - Index de navigation principal
- `MEDIA_USAGE_EXAMPLE.md` - Exemples d'utilisation média
- `EXEMPLE_UPLOAD_COMPLET.md` - Exemple complet d'upload
- `MEDIA_SERVICE_AMELIORE.md` - Service média amélioré
- `RESUME_MODIFICATIONS_POSTS_MESSAGES.md` - Résumé modifications
- `RESUME_VALIDATION_MEDIAS.md` - Résumé validation
- `FICHIERS_MODIFIES_SESSION.md` - Historique session
- `REPONSE_FINALE.md` - Réponses aux questions

## Statistiques

### Avant réorganisation
- Fichiers .md à la racine du projet : 15
- Fichiers .md dispersés : Oui
- Navigation difficile : Oui

### Après réorganisation
- Fichiers .md à la racine du projet : 1 (README.md)
- Sous-dossiers thématiques : 9
- Fichiers .md organisés : 72
- README par dossier : Oui
- Index central : Oui

## Bénéfices de l'organisation

### 1. Navigation améliorée
- Structure claire et logique
- Facile de trouver la documentation recherchée
- Index centralisé avec liens directs

### 2. Maintenance facilitée
- Ajout de nouveaux documents simplifié
- Mise à jour ciblée par thématique
- Éviter les doublons

### 3. Compréhension rapide
- README par dossier explique le contenu
- Documentation groupée par logique métier
- Accès rapide aux informations pertinentes

### 4. Scalabilité
- Facile d'ajouter de nouveaux dossiers
- Structure extensible
- Prêt pour la croissance du projet

## Guide d'utilisation

### Pour trouver une documentation

1. **Par thématique** : Consultez la liste des dossiers ci-dessus
2. **Par index** : Ouvrez [INDEX.md](INDEX.md) pour une vue complète
3. **Par README** : Chaque dossier a un README.md expliquant son contenu

### Pour ajouter une nouvelle documentation

1. Identifiez le dossier thématique approprié
2. Ajoutez votre fichier .md dans ce dossier
3. Mettez à jour le README.md du dossier
4. Mettez à jour INDEX.md si nécessaire

### Règles de nommage

- Utilisez MAJUSCULES_AVEC_UNDERSCORES.md pour les documents importants
- Soyez descriptif dans le nom du fichier
- Évitez les noms trop longs (max 50 caractères)

## Points d'entrée recommandés

### Pour les développeurs frontend
→ [INDEX.md](INDEX.md) puis [features/](features/)

### Pour les développeurs backend
→ [README.md](README.md) puis les fichiers MAPPING

### Pour le déploiement
→ [deploiement/QUICK_START.md](deploiement/QUICK_START.md)

### Pour comprendre l'architecture
→ [architecture/SERVICES_ARCHITECTURE.md](architecture/SERVICES_ARCHITECTURE.md)

### Pour les comparaisons IS/IU
→ [comparisons/](comparisons/)

## Maintenance continue

### Checklist mensuelle
- [ ] Vérifier que tous les fichiers sont dans le bon dossier
- [ ] Mettre à jour les README si nouveaux fichiers
- [ ] Supprimer les documents obsolètes
- [ ] Mettre à jour l'INDEX.md

### Checklist avant release
- [ ] Tous les fichiers de mapping à jour
- [ ] Documentation déploiement vérifiée
- [ ] README.md avec version actuelle
- [ ] Pas de fichiers orphelins

## Historique des réorganisations

| Date | Version | Changements |
|------|---------|-------------|
| 2026-01-08 | 2.0 | Réorganisation complète en sous-dossiers thématiques |
| 2025-01-04 | 1.5 | Ajout dossier deploiement |
| 2025-12-02 | 1.0 | Structure initiale |

## Contact

Pour toute question sur l'organisation de la documentation :
1. Consultez d'abord [INDEX.md](INDEX.md)
2. Vérifiez le README.md du dossier concerné
3. Contactez l'équipe de développement

---

**Dernière mise à jour** : 2026-01-08
**Auteur** : Équipe Titingre
**Version** : 2.0
