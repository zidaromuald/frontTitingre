# Exclusion de la Documentation lors du Déploiement Web

## Pourquoi exclure la documentation ?

La documentation (fichiers .md) est uniquement destinée aux développeurs et ne doit pas être déployée sur le serveur web Hostinger pour :
- Réduire la taille du déploiement
- Éviter d'exposer des informations internes
- Améliorer les performances de chargement

## Comment ça fonctionne ?

### Automatique avec Flutter

Flutter ne déploie **que les fichiers déclarés** dans la section `assets:` du `pubspec.yaml`.

**Notre configuration actuelle :**
```yaml
assets:
  - images/logo.png
  - images/icon.png
```

**Résultat :** Le dossier `lib/services/documentation/` n'est PAS inclus dans `build/web/` automatiquement.

### Vérification

Pour vérifier que la documentation n'est pas dans le build :

```bash
# 1. Faire le build web
flutter build web --release

# 2. Vérifier que documentation n'existe pas
ls build/web/assets/lib/services/documentation
# Devrait retourner "No such file or directory"

# 3. Voir ce qui est inclus
ls -la build/web/assets/
```

## Documentation reste dans Git

La documentation **est versionnée dans Git** pour :
- ✅ Collaboration entre développeurs
- ✅ Historique des modifications
- ✅ Accès facile depuis le repository
- ✅ Synchronisation entre machines

**Mais ne sera jamais déployée sur le web !**

## Script de déploiement

Un script bash est disponible pour faciliter le déploiement : `scripts/deploy_web.sh`

```bash
# Utilisation
chmod +x scripts/deploy_web.sh
./scripts/deploy_web.sh
```

Ce script :
1. Nettoie les builds précédents
2. Build l'application web
3. Vérifie que la documentation n'est pas incluse
4. Affiche la taille du build final

## Déploiement sur Hostinger

### Méthode 1 : File Manager (Recommandé)

```bash
# 1. Build web
flutter build web --release

# 2. Compresser
cd build/web
zip -r titingre-web.zip .

# 3. Uploader sur Hostinger File Manager
# 4. Décompresser dans public_html/
```

### Méthode 2 : FTP/SFTP

```bash
# 1. Build web
flutter build web --release

# 2. Upload via FTP (exemple avec lftp)
lftp -u votre_user,votre_password ftp.votresite.com
cd public_html
mirror -R build/web .
quit
```

### Méthode 3 : Git sur le serveur (Non recommandé)

Si vous clonez le repository directement sur le serveur :

```bash
# Sur le serveur
git clone votre-repo.git
cd votre-repo
flutter build web --release
cp -r build/web/* /path/to/public_html/
```

**Attention :** Même si vous clonez le repo avec la documentation, celle-ci ne sera pas dans `build/web/`.

## Vérification après déploiement

Testez que la documentation n'est pas accessible publiquement :

```bash
# Ces URLs ne devraient PAS fonctionner
https://www.titingre.com/assets/lib/services/documentation/README.md
https://www.titingre.com/assets/lib/services/documentation/INDEX.md
```

Résultat attendu : **404 Not Found**

## Résumé

| Élément | Dans Git | Dans Build Web | Sur Hostinger |
|---------|----------|----------------|---------------|
| Code Dart (.dart) | ✅ Oui | ✅ Oui (compilé) | ✅ Oui |
| Images (logo, icon) | ✅ Oui | ✅ Oui | ✅ Oui |
| Documentation (.md) | ✅ Oui | ❌ Non | ❌ Non |
| pubspec.yaml | ✅ Oui | ❌ Non | ❌ Non |

## FAQ

**Q : La documentation prend de la place dans Git ?**
R : Oui, mais c'est normal. Les fichiers .md sont légers (~50-100 Ko chacun).

**Q : Peut-on accéder à la doc depuis le web ?**
R : Non, elle n'est jamais déployée. Accessible uniquement via le repository Git.

**Q : Que se passe-t-il si j'ajoute la doc aux assets ?**
R : Elle serait alors incluse dans le build et déployée. **Ne pas faire !**

**Q : Comment partager la doc avec l'équipe ?**
R : Via Git (push/pull) ou en exportant le dossier documentation en .zip.

## Checklist de déploiement

Avant chaque déploiement :

- [ ] `flutter build web --release` exécuté
- [ ] Vérifier que `build/web/assets/lib/services/documentation` n'existe pas
- [ ] Taille du build < 10 MB (sans la doc)
- [ ] Upload sur Hostinger
- [ ] Tester que les URLs de doc retournent 404

---

**Dernière mise à jour** : 2026-01-08
**Auteur** : Équipe Titingre
